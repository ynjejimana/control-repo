#!/usr/bin/perl
#### Monitoring OVM Hypervisor
#### Version 2.26
#### Writen by: Phil Shead (pshead@harbourmsp.com)
#### Modifications: Premysl Botek (pbotek@harbourmsp.com)
##################################################################################

## compiler declarations, environment setup

use v5.10;
use strict;
use Config::Simple;
use Data::Dumper;
use Net::OpenSSH;
use Time::Piece;
use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);
use DBI;
use Switch;

my $loggingLevel = 2
  ; # 0 - no logging, 1 - log errors only, 2 - log everything (errors, warnings, debug info)
my $logOutput = 3
  ; # 1 - output to console, 2 - output to log file, 3 - output to both console and log file

my $collectPCPUStats = 0;   #1 yes, 0 no. Runs xenmonv2.py to collect PCPU stats

my $hypervisorConnectionTimeout = 30;    # in seconds
my $hypervisorQueryTimeout      = 30;    # in seconds

our $basedir          = "/srv/zabbix/scripts/ovmmonitoring";
our $logFileName      = "$basedir/log.txt";
our $databasefilename = "$basedir/ovmmonitoringdata.db";

our $delim = "#####";
my $thisModuleID =
  "GET-HYPERVISOR-STATS";    # just for log file record identification purposes
our %starttimes;
our %mappednames;

our $total_cpu_usage       = 0;
our $cpu_subscription      = 0;
our $subscribed_cpus_count = 0;
our $no_of_cpus            = 0;
our $no_of_vms             = 0;

our $delimcmd       = "echo \"$delim\"";
our $versioncmd     = "cat /etc/redhat-release";
our $xminfocmd      = "sudo /usr/sbin/xm info";
our $hyperuptimecmd = "cat /proc/uptime";
our $dfcmd          = "sudo /bin/df";
our $xenmoncmd      = "sudo /srv/zabbix/xenmonv2.py";

our $mapnamescmd;
our $xmlistcmd =
'sudo /usr/sbin/xm list -l | grep -e start_time -e "(name" | grep -v Domain | tr -s "\' \'" |sed -e "s/ (name//g" -e "s/ (start_time//g" -e "s/)//g" -e "s/^ //g" | sed "{:q;N;s/\n/ /g;t q}"';

our $xentopcmd1 =
  "sudo /usr/sbin/xentop -f -b -i2 -d 5 -r -v -n -x"
  ; # used for for querying hypervisor v 3.2.2 and 3.1.1 - use -f parameter to show full VM uuids, then remap them because top command won't give us friendly VM names
our $xentopcmd2 =
  "sudo /usr/sbin/xentop -b -i2 -d 5 -r -v -n -x"
  ; # used for querying hypervisor v 2.2.1 - shows friendly VM names (-f parameter is missing)
our $xentopcmd = "";

my $cluster;

my $configfile;

my $ssh_pipe;

my $hypervisor_version;
my $detectedSupportedHypervisorVersion =
  0;    # 0 = unknown, 1 = 3.2.2, 2 = 2.2.1, 3 = 3.1.1
my $hypervisor_uptime;
my $dom_starttime;

my $global_seq_no;
my $cluster_seq_no;

my $executionResult_versioncmd;

my $executionResult_mapnamescmd;
my $executionResult_hyperuptimecmd;
my $executionResult_xmlistcmd;
my $executionResult_xminfocmd;
my $executionResult_xentopcmd;
my $executionResult_dfcmd;
my $executionResult_xenmoncmd;

my $failedRemoteCommandsCount = 0;

my @collectedDetails_versioncmd;

my @collectedDetails_mapnamescmd;
my @collectedDetails_hyperuptimecmd;
my @collectedDetails_xmlistcmd;
my @collectedDetails_xminfocmd;
my @collectedDetails_xentopcmd;
my @collectedDetails_dfcmd;
my @collectedDetails_xenmoncmd;

my $stderr1;

## program entry point
## program initialization

if ( $#ARGV < 0 ) {

	print <<USAGELABEL;
Invalid command line parameters
	
USAGE:		perl get-hypervisor-stats.pl <hypervisor>

RETURNS:	either nothing or an error message
	
LOGGING:	set $loggingLevel variable : 0 - no logging, 1 - log errors only, 2 - log everything (errors, warnings, debug info)

			set $logOutput variable : 1 - output to console, 2 - output to log file, 3 - output to both console and log file
	
USAGELABEL

	exit 0;
}

if ( !defined( $ARGV[0] ) ) {
	$cluster = "dev";
}    # execution should never get here if command line is empty but anyway...
else { $cluster = $ARGV[0] }

$configfile = "$basedir/clusters/$cluster.ini";

if ( !$configfile ) {
	logEvent( 2, "Can not open config file $configfile" );
	exit 1;
}
else {
	if ( !-f $configfile ) {
		logEvent( 2, "Can not open config file $configfile" );
		exit 1;
	}
}

logEvent( 1, "Using config file $configfile" );

my $cfg = new Config::Simple("$configfile");

our $clustername      = $cfg->param('cluster.clustername');
our @hypervisors      = $cfg->param('cluster.hypervisors');
our $monitoruser      = $cfg->param('cluster.monitoruser');
our $clusteruuidremap = $cfg->param('cluster.uuidremap');

our $uuidremap = 0;
our $uuidremapconfigfilepath;

# connect to database

if ( !-f $databasefilename ) {
	logEvent( 2, "Database file $databasefilename does not exist" );
	exit 1;
}

my $dbh = DBI->connect(
	"dbi:SQLite:dbname=$databasefilename",
	"", "", { RaiseError => 1 },
  )

  || { logEvent( 2, "Can't connect to database: $DBI::errstr" )
	  && exit 1 };

# maintain TA_COLLECTED_DATA table (delete outdated records)
maintainDataRetention() or exit 1;

$dbh->begin_work();

my $sql1 = <<DELIMITER1;

SELECT 

(
SELECT MAX(DL_GLOBAL_SEQ_NUMBER) FROM TA_COLLECTED_DATA 
) AS LAST_GLOBAL_SEQ_NO
,
(
SELECT MAX(DL_CLUSTER_SEQ_NUMBER) FROM TA_COLLECTED_DATA
WHERE DS_STATNAME LIKE 'metadata:seqheader:param1%'
) AS LAST_CLUSTER_SEQ_NUMBER

DELIMITER1

$sql1 =~ s/param1/$clustername/g
  ; # parameters in complex parametrized sqlite queries do not work well. we do parameter replacement ourselves

my $sth1 = $dbh->prepare($sql1);

$sth1->execute();

( $global_seq_no, $cluster_seq_no ) = $sth1->fetchrow_array();

$sth1->finish();

if ( !defined($global_seq_no) ) {
	$global_seq_no = 0;
}

if ( !defined($cluster_seq_no) ) {
	$cluster_seq_no = 0;
}

$global_seq_no++;
$cluster_seq_no++;

my $sql1 =
"INSERT INTO TA_COLLECTED_DATA (DL_GLOBAL_SEQ_NUMBER,DL_CLUSTER_SEQ_NUMBER,DS_STATNAME) VALUES (?,?,?)";

my $sth1 = $dbh->prepare($sql1);

$sth1->execute( $global_seq_no, $cluster_seq_no,
	"metadata:seqheader:" . $clustername );

$dbh->commit();

## main execution block

foreach my $hypervisor (@hypervisors) {
	$total_cpu_usage       = 0;
	$cpu_subscription      = 0;
	$subscribed_cpus_count = 0;

	get_hyper_info( $hypervisor, $clustername, $monitoruser );
}

## end - main execution block

my $sql1 =
"INSERT INTO TA_COLLECTED_DATA (DL_GLOBAL_SEQ_NUMBER,DL_CLUSTER_SEQ_NUMBER,DS_STATNAME) VALUES (?,?,?)";

my $sth1 = $dbh->prepare($sql1);

$sth1->execute( $global_seq_no, $cluster_seq_no,
	"metadata:seqfooter:" . $clustername );

# disconnect from database
$dbh->disconnect()
  || { logEvent( 2, "Can't disconnect from database: $DBI::errstr" )
	  && exit 1 };

##  program exit point	###########################################################################

sub dumpArrayToString {
	my (@array1) = @_;
	my $returnValue = "";

	foreach my $item (@array1) {

		$returnValue .= $item;
	}

	return $returnValue;

}

sub query_hypervisor {
	my ( $cmd, $collectedDetails_ref, $hypervisor, $ip ) =
	  @_;    # expects reference to $collectedDetails

	logEvent( 1, "Executing Remote SSH command : $cmd" );

	my ( $sshReadBuffer, $errput ) =
	  $ssh_pipe->capture2(
		{ timeout => $hypervisorQueryTimeout, stdin_discard => 1 }, $cmd )
	  ; # doco says that capture function honours input separator settings (local $/ = "\n";) when in array context, but really it does not...

#	!Don't use statement " || { logEvent( 2, "Error 1 occured in query_hypervisor() : " . $ssh_pipe->error )
#		  && return 0 }; " in here or $errput will not be retrieved correctly...

	if ( $ssh_pipe->error ) {
		logEvent( 2,
"Error 1 occured in query_hypervisor(): Hypervisor: $hypervisor\nIP: $ip\nCMD : $cmd\nSTDIN: $sshReadBuffer\nSTDERR: $errput\nNet::SSH error : "
			  . $ssh_pipe->error );

		return 0;
	}

	if ( !( $errput eq "" ) ) {

		if ( !( $errput =~ m/^ms_per_sample/ ) ) {

			$errput =~ s/\n//g;
			logEvent( 2,
"Error 2 occured in query_hypervisor(): Hypervisor: $hypervisor\nIP: $ip\nCMD : $cmd\nSTDIN: $sshReadBuffer\nSTDERR: $errput\nNet::SSH error : "
				  . $ssh_pipe->error );

			return 0;
		}
	}

	@$collectedDetails_ref = split "\n",
	  $sshReadBuffer;    # modifies referred array, wot a beauti
	foreach my $item (@$collectedDetails_ref) {

		$item = $item . "\n";
	}

	logEvent( 1,
		"Remote command result: " . dumpArrayToString(@$collectedDetails_ref) );

	return 1;

}

sub get_hyper_info {
	my ( $hypervisor_ip, $clustername, $monitoruser ) = @_;
	my ( $hypervisor, $ip ) = split( /:/, $hypervisor_ip );

	logEvent( 1, "Querying hypervisor $hypervisor:$ip" );

	$no_of_vms = 0;

	my $cmd;

	$ssh_pipe = Net::OpenSSH->new(
		$ip,
		master_opts => [
			-o => "StrictHostKeyChecking=no",
			-o => "ConnectTimeout $hypervisorConnectionTimeout"
		],
		user => "$monitoruser",

#		password    => '',			# use this if you do not want passwordless authentication
		strict_mode => 0,

	);

	$ssh_pipe->error
	  && {
		logEvent( 2,
			"SSH connection to hypervisor $hypervisor ($ip) failed: "
			  . $ssh_pipe->error )
		  && exit 1
	  };

## run $versioncmd
	if (
		query_hypervisor(
			"$versioncmd;", \@collectedDetails_versioncmd,
			$hypervisor, $ip
		)
	  )
	{
		$executionResult_versioncmd = 0;
	}
	else {
		$executionResult_versioncmd = 1;
		$failedRemoteCommandsCount++;
	}

	parsedetails_hyperversion(@collectedDetails_versioncmd);

## run $mapnamescmd

	logEvent( 1, "mappednames1" );

	if ($uuidremap) {
		if (
			query_hypervisor(
				"$mapnamescmd;", \@collectedDetails_mapnamescmd,
				$hypervisor,     $ip
			)
		  )
		{
			$executionResult_mapnamescmd = 0;
		}
		else {
			$executionResult_mapnamescmd = 1;
			$failedRemoteCommandsCount++;
		}

		logEvent( 1, "mappednames3" );

		parsedetails_mapnames(@collectedDetails_mapnamescmd);

		logEvent( 1, "mappednames4" );

	}

	logEvent( 1, "mappednames5" );

## run $hyperuptimecmd

	if (
		query_hypervisor(
			"$hyperuptimecmd;", \@collectedDetails_hyperuptimecmd,
			$hypervisor,        $ip
		)
	  )
	{

		$executionResult_hyperuptimecmd = 0;

	}
	else {
		$executionResult_hyperuptimecmd = 1;
		$failedRemoteCommandsCount++;
	}

	parsedetails_hyperuptime(@collectedDetails_hyperuptimecmd);

## run $xmlistcmd
	if (
		query_hypervisor(
			"$xmlistcmd; $delimcmd", \@collectedDetails_xmlistcmd,
			$hypervisor,             $ip
		)
	  )
	{
		$executionResult_xmlistcmd = 0;

	}
	else {
		$executionResult_xmlistcmd = 1;
		$failedRemoteCommandsCount++;
	}

	parsedetails_xmlist(@collectedDetails_xmlistcmd);

## run $xminfocmd

	if (
		query_hypervisor(
			"$xminfocmd; $delimcmd;", \@collectedDetails_xminfocmd,
			$hypervisor,              $ip
		)
	  )
	{
		$executionResult_xminfocmd = 0;

	}
	else {
		$executionResult_xminfocmd = 1;
		$failedRemoteCommandsCount++;
	}

	parsedetails_xminfo(@collectedDetails_xminfocmd);

## run $xentopcmd
	if (
		query_hypervisor(
			"$xentopcmd;", \@collectedDetails_xentopcmd,
			$hypervisor, $ip
		)
	  )
	{
		$executionResult_xentopcmd = 0;

	}
	else {
		$executionResult_xentopcmd = 1;
		$failedRemoteCommandsCount++;
	}

## run dfcmd
	if (
		query_hypervisor(
			"$dfcmd;", \@collectedDetails_dfcmd, $hypervisor, $ip
		)
	  )
	{
		$executionResult_dfcmd = 0;

	}
	else {
		$executionResult_dfcmd = 1;
		$failedRemoteCommandsCount++;
	}

##

## run xenmoncmd

	if ( $collectPCPUStats == 1 ) {

		if (
			query_hypervisor(
				"$xenmoncmd;", \@collectedDetails_xenmoncmd,
				$hypervisor,   $ip
			)
		  )
		{
			$executionResult_xenmoncmd = 0;

		}
		else {
			$executionResult_xenmoncmd = 1;
			$failedRemoteCommandsCount++;
		}

	}

##

	analyse_vm_details( $hypervisor, $no_of_vms, @collectedDetails_xentopcmd );
	analyse_hypervisor_details($hypervisor);

	saveExecutionResultsMetadata1($hypervisor);

}

sub parsedetails_hyperversion {

	my (@data) = @_;
	my $clusterremapcmd;

	chop( $hypervisor_version = shift @data );

	switch ($hypervisor_version) {

		case "Oracle VM server release 3.1.1" {
			$detectedSupportedHypervisorVersion = 3;
			$xentopcmd                          = $xentopcmd1;
			$uuidremap                          = 1;

		}

		case "Oracle VM server release 3.2.2" {
			$detectedSupportedHypervisorVersion = 1;
			$xentopcmd                          = $xentopcmd1;
			$uuidremap                          = 1;

		}

		case "Oracle VM server release 2.2.1" {
			$detectedSupportedHypervisorVersion = 2;
			$xentopcmd                          = $xentopcmd2;

		}
		else {    # we will act as if we detected 3.2.2 but not in everything
			$detectedSupportedHypervisorVersion = 0;
			$xentopcmd                          = $xentopcmd1;
			$uuidremap                          = 1;
		}
	}

# if we decide to remap VM names, formulate the correct $mapnamescmd, basing on hypervisor version (2.2.1 does not need VM names remapping because its top command shows friendly VM names)
	if ($uuidremap) {
		switch ($detectedSupportedHypervisorVersion) {

			case [ 1, 3, 0 ] {    # for hypervisor 3.2.2, 3.1.1 or undetected

				$uuidremapconfigfilepath = "/OVS/Repositories";

#				$clusterremapcmd =
#"sudo /bin/cat \`sudo /usr/bin/find $uuidremapconfigfilepath -name vm.cfg -print 2>&1 | grep -v snapshot\`";

				$clusterremapcmd =
"sudo /bin/cat \`sudo /usr/bin/find $uuidremapconfigfilepath -name vm.cfg -print 2>&1 | grep VirtualMachines/`";

				if ($uuidremapconfigfilepath) {
					$uuidremap = 1;
					$mapnamescmd =
"$clusterremapcmd | grep name | sed -e \"s/.* = //g\" | tr \"\\n\" \",\";echo";
				}

			}

		}

	}
}

sub parsedetails_mapnames {
	my (@data) = @_;
	chop( my $uptimedetails = shift @data );
	chop $uptimedetails;
	$uptimedetails =~ s/'//g;
	my @mappedvmnames = split( /,/, $uptimedetails );
	while (@mappedvmnames) {
		my $name = shift @mappedvmnames;
		my $uuid = shift @mappedvmnames;
		$mappednames{$uuid} = $name;

	}
	$mappednames{"Domain-0"} = "Domain-0";

	logEvent( 1, "mappednames2" );

	logEvent( 1, "mappednames: " . Dumper( \%mappednames ) );

}

sub parsedetails_hyperuptime {

	my (@data) = @_;

	chop( my $uptimedetails = shift @data );

	my ( $uptime, $rest ) = split( / /, $uptimedetails );
	$hypervisor_uptime = int $uptime;
	$dom_starttime     = time - $uptime;

	my ( $hyperuptime, $rest ) = split( / /, $uptime );

}

sub parsedetails_xmlist {

	my (@data) = @_;

	chop( my $tmpStartTimes = shift @data );

	if ( $tmpStartTimes eq "#####" ) {
		unshift @data, "$tmpStartTimes\n";
		$tmpStartTimes = "";
	}

	my @tmpStartTimes = split( / /, $tmpStartTimes );

	while (@tmpStartTimes) {
		my $name      = shift @tmpStartTimes;
		my $starttime = shift @tmpStartTimes;
		$starttimes{$name} = int $starttime;
		$no_of_vms++;

	}
	$starttimes{"Domain-0"} = int $dom_starttime;
	$no_of_vms++;

}

sub parsedetails_xminfo {
	my (@data) = @_;

	$no_of_cpus = getval( "nr_cpus", @data );

	if ( $no_of_cpus == 0 ) {
		logEvent( 2, "Retrieved number of CPUs is 0, can not continue." );
		exit 1;

	}

}

###############

sub writeCollectedInfoKeypairToDatabase1 {  # needs to work within a transaction

	my ( $statname1, $value1 ) = @_;
	my $subresult = 0;

	eval {

		my $sql1 =
"INSERT INTO TA_COLLECTED_DATA(DS_STATNAME,DS_VALUE, DL_GLOBAL_SEQ_NUMBER,DL_CLUSTER_SEQ_NUMBER) VALUES (\"$statname1\",\"$value1\",$global_seq_no,$cluster_seq_no)";

		$dbh->do($sql1);

		$subresult = 1;
		return
		  ; # returns only from this eval block, not from the sub. Very "smart" feature of Perl...

	};

	if ($@) {

		logEvent( 2, "Error 2 occured in writeKeypairToDatabase1(): $@" );

		eval { $dbh->rollback(); };

	}

	return $subresult;

}

sub writeSettingToDatabase1 {

	my ( $key1, $value1 ) = @_;
	my $subresult = 0;

	eval {

		$dbh->begin_work();

		my $sql1 =
		  "UPDATE TA_SETTINGS SET DS_VALUE=\"$value1\" WHERE DS_KEY=\"$key1\"";

		$dbh->do($sql1);

		$dbh->commit();

		$subresult = 1;

		return
		  ; # returns only from this eval block, not from the sub. Very "smart" feature of Perl...

	};

	if ($@) {

		logEvent( 2, "Error 1 occured in writeKeypairToDatabase1(): $@" );

		eval { $dbh->rollback(); };

	}

	return $subresult;

}

sub readSettingFromDatabase1 {
	my ( $key1, $value1 )
	  =    # expects reference to variable $value1 (so it can modify it)
	  @_;
	my $tmp1;
	my $tmp2;
	my $subresult = 0;

	eval {

		my $sql1 = "SELECT DS_VALUE FROM TA_SETTINGS WHERE DS_KEY=\"$key1\"";

		my $sth = $dbh->prepare($sql1);

		$sth->execute();

		$tmp1 = $sth->fetch();

		$sth->finish();   # end statement, release resources (not a transaction)

		if ( !defined($tmp1) ) {

			logEvent( 2, "The setting value for the key $key1 does not exist" );
			return
			  ; # returns only from this eval block, not from the sub. Very "smart" feature of Perl...
		}

		$$value1 =
		  @$tmp1[0]
		  ; # dereference array referenced by $tmp1, retrieve its first item and store it in a scalar variable that is referenced by $value1

		$subresult = 1;
		return
		  ; # returns only from this eval block, not from the sub. Very "smart" feature of Perl...

	};

	if ($@) {

		logEvent( 2, "Error 1 occured in readSettingFromDatabase1(): $@" );

	}

	return $subresult;

}

sub maintainDataRetention {
	my $subresult = 0;
	my $dataRetentionPeriod;
	my $rowsAffected;

	readSettingFromDatabase1( "DATA_RETENTION_PERIOD", \$dataRetentionPeriod )
	  or return $subresult;

	if ( !defined($dataRetentionPeriod) ) {
		logEvent( 2, "DATA_RETENTION_PERIOD does not exist in TA_SETTINGS" );
		return $subresult;

	}

	eval {

		my $sql1 =
"DELETE FROM TA_COLLECTED_DATA WHERE DATETIME(DT_TIMESTAMP)<DATETIME(DATETIME( 'now' , 'localtime' ),'-"
		  . $dataRetentionPeriod
		  . " minute')";

		my $sth = $dbh->prepare($sql1);

		$rowsAffected =
		  $sth->execute()
		  ; # no need for manual transaction, we are just running one statement here

		$sth->finish();   # end statement, release resources (not a transaction)

		if ( $rowsAffected == 0 ) {    # just so we dont get 0E0
			$rowsAffected = 0;
		}

		logEvent( 1,
			"Maintaining Data Retention, $rowsAffected rows deleted." );

		$subresult = 1;
	};

	if ($@) {

		logEvent( 2, "Error 1 occured in maintainDataRetention(): $@" );

	}

	return $subresult;

}

##################

#
# saves the remote commands execution results under the "metadata" naming domain for the current sequence
sub saveExecutionResultsMetadata1 {
	my ($hypervisor) = @_;

	#	my $statNamingDomain              = "metadata";
	#	my $collectedInfoKeypairStorePath =
	#	  $clustername . "_" . $statNamingDomain . "_" . $hypervisor . "_";

	my $collectedInfoKeypairStorePath =
	  "metadata:" . $clustername . ":" . $hypervisor . ":";

	eval {

		$dbh->begin_work();

		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "executionResult-versioncmd",
			$executionResult_versioncmd )
		  || exit 1;

		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "executionResult-mapnamescmd",
			$executionResult_mapnamescmd )
		  || exit 1;

		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "executionResult-hyperuptimecmd",
			$executionResult_hyperuptimecmd )
		  || exit 1;

		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "executionResult-xmlistcmd",
			$executionResult_xmlistcmd )
		  || exit 1;

		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "executionResult-xminfocmd",
			$executionResult_xminfocmd )
		  || exit 1;

		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "executionResult-xentopcmd",
			$executionResult_xentopcmd )
		  || exit 1;

		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "failed-Remote-Commands-Count",
			$failedRemoteCommandsCount )
		  || exit 1;

		$dbh->commit();
	};
	if ($@) {

		logEvent( 2, "Error 1 occured in saveExecutionResultsMetadata1(): $@" );

		exit 1;

	}

}

sub analyse_hypervisor_details {

	my ($hypervisor) = @_;

	my $host = $hypervisor;

	my $machine = getval( "machine", @collectedDetails_xminfocmd );
	my $cores_per_socket =
	  getval( "cores_per_socket", @collectedDetails_xminfocmd );
	my $threads_per_core =
	  getval( "threads_per_core", @collectedDetails_xminfocmd );
	my $total_memory = getval( "total_memory", @collectedDetails_xminfocmd );
	my $free_memory  = getval( "free_memory",  @collectedDetails_xminfocmd );
	my $major        = getval( "major",        @collectedDetails_xminfocmd );
	my $minor        = getval( "minor",        @collectedDetails_xminfocmd );
	my $extra        = getval( "extra",        @collectedDetails_xminfocmd );
	my $pagesize     = getval( "pagesize",     @collectedDetails_xminfocmd );

	my $xenversion = "$major.$minor$extra";

	#my $available_memory = $free_memory;
	my $allocated_memory = $total_memory - $free_memory;
	my $mem_per =
	  sprintf( "%.1f", ( $allocated_memory / $total_memory ) * 100 );

	my @vmdata = getblock(
		"NAME",
		$no_of_vms + 1,
		$no_of_vms + $no_of_vms + 1,
		@collectedDetails_xentopcmd
	);

	# d----- domain is dying
	my @result = grep( /d-----/, @vmdata );
	my $dying = $#result + 1;

	# -s---- domain shutting down
	my @result = grep( /-s----/, @vmdata );
	my $shutting = $#result + 1;

	# --b--- blocked domain
	my @result = grep( /--b---/, @vmdata );

	#print "results = '@result'\n";
	my $blocked = $#result + 1;

	# ---c-- domain crashed
	my @result = grep( /---c--/, @vmdata );
	my $crashed = $#result + 1;

	# ----p- domain paused
	my @result = grep( /----p-/, @vmdata );
	my $paused = $#result + 1;

	# -----r domain is actively running on one of the CPU
	my @result = grep( /-----r/, @vmdata );
	my $running = $#result + 1;

	my $max_cpu_usage_total = $no_of_cpus * 100;

	my $free_cpu_usage = $max_cpu_usage_total - $total_cpu_usage;

	my $scaled_total_cpu_usage = sprintf "%.2f", $total_cpu_usage / $no_of_cpus;

	my $scaled_free_cpu_usage = 100 - $scaled_total_cpu_usage;

	$cpu_subscription = sprintf "%.2f",
	  ( $cpu_subscription / $no_of_cpus ) * 100;

	#	my $statNamingDomain              = "hyper";
	#	my $collectedInfoKeypairStorePath =
	#	  $clustername . "_" . $statNamingDomain . "_" . $hypervisor . "_";
	#

	my $collectedInfoKeypairStorePath =
	  "hyper:" . $clustername . ":" . $hypervisor . ":";

	eval {

		$dbh->begin_work();

		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "host", $host )
		  || exit 1;
		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "machine", $machine )
		  || exit 1;
		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "version",
			$hypervisor_version )
		  || exit 1;
		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "xenversion", $xenversion )
		  || exit 1;    # we never got this data previously
		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "no_of_cpus", $no_of_cpus )
		  || exit 1;
		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "cores_per_socket",
			$cores_per_socket )
		  || exit 1;
		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "threads_per_core",
			$threads_per_core )
		  || exit 1;
		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "total_memory",
			$total_memory )
		  || exit 1;
		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "free_memory", $free_memory )
		  || exit 1;

		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "mem_per", $mem_per )
		  || exit 1;

		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "allocated_memory",
			$allocated_memory )
		  || exit 1;
		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "pagesize", $pagesize )
		  || exit 1;
		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "no_of_vms", $no_of_vms )
		  || exit 1;
		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "domstarttime",
			$dom_starttime )
		  || exit 1;
		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "uptime",
			$hypervisor_uptime )
		  || exit 1;
		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "max_cpu_usage_total",
			$max_cpu_usage_total )
		  || exit 1;
		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "total_cpu_usage",
			$total_cpu_usage )
		  || exit 1;
		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "free_cpu_usage",
			$free_cpu_usage )
		  || exit 1;
		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "scaled_total_cpu_usage",
			$scaled_total_cpu_usage )
		  || exit 1;
		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "scaled_free_cpu_usage",
			$scaled_free_cpu_usage )
		  || exit 1;
		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "cpu_subscription",
			$cpu_subscription )
		  || exit 1;
		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "subscribed_cpus_count",
			$subscribed_cpus_count )
		  || exit 1;
		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "dying", $dying )
		  || exit 1;
		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "shutting", $shutting )
		  || exit 1;
		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "blocked", $blocked )
		  || exit 1;
		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "crashed", $crashed )
		  || exit 1;
		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "paused", $paused )
		  || exit 1;

		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "running", $running )
		  || exit 1;

		writeCollectedInfoKeypairToDatabase1(
			$collectedInfoKeypairStorePath . "mountinfo",
			join( "\n", @collectedDetails_dfcmd )
		) || exit 1;

		if ( $collectPCPUStats == 1 ) {
			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . "xenmoninfo",
				join( "\n", @collectedDetails_xenmoncmd )
			) || exit 1;

		}

		$dbh->commit();
	};
	if ($@) {

		logEvent( 2, "Error 1 occured in analyse_hypervisor_details(): $@" );

		exit 1;

	}

}

sub analyse_vm_details {
	my ( $hypervisor, $no_of_vms, @data ) = @_;
	my $time = time;

	for ( my $loop = $no_of_vms + 1 ; $loop <= $no_of_vms * 2 ; $loop++ ) {
		my @results = getblock( "NAME", $loop, $loop, @data );
		chop( my $vm = shift @results );

		$vm = cleandata($vm);

		my (
			$vmname, $state,  $secs,    $util,  $memk,
			$memp,   $maxmem, $maxmemp, $vcpus, @blah
		) = split( /,/, $vm );

		my $starttime = $starttimes{$vmname};
		my $uptime    = int( $time - $starttime );
		my $fullname  = $vmname;

		if ($uuidremap) {
			$fullname = $mappednames{$vmname};
		}

		#increment the total overall usage
		$fullname =~ s/^Domain-0/$hypervisor-Domain-0/;
		my $countvcpus =
		  analyse_vcpu_details( $hypervisor, $fullname, @results );
		$total_cpu_usage += $util;

		if ( $vmname ne "Domain-0" ) {

			$cpu_subscription      += $countvcpus;
			$subscribed_cpus_count += $countvcpus;
		}

		my $scaled_cpu_perc = sprintf "%3.2f", ( $util / $no_of_cpus );
		my $capped_cpu_allocated = sprintf "%3.2f",
		  ( $vcpus / $no_of_cpus ) * 100;
		my $available_cpu = $capped_cpu_allocated - $scaled_cpu_perc;

		analyse_net_details( $hypervisor, $fullname, @results );
		analyse_vbd_details( $hypervisor, $fullname, @results );

		#		my $statNamingDomain = "vm";
		#
		#		my $collectedInfoKeypairStorePath =
		#		  $clustername . "_" . $statNamingDomain . "_" . $fullname . "_";

		my $collectedInfoKeypairStorePath =
		  "vm:" . $clustername . ":" . $hypervisor . ":" . $fullname . ":";

		eval {

			$dbh->begin_work();

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . "hypervisor", $hypervisor )
			  || exit 1;

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . "fullname", $fullname )
			  || exit 1;

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . "state", $state )
			  || exit 1;

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . "start_time", $starttime )
			  || exit 1;

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . "uptime", $uptime )
			  || exit 1;

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . "cpu_sec", $secs )
			  || exit 1;

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . "cpu_util", $util )
			  || exit 1;

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . "scaled_cpu_perc",
				$scaled_cpu_perc )
			  || exit 1;

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . "capped_cpu_allocated",
				$capped_cpu_allocated )
			  || exit 1;

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . "available_cpu",
				$available_cpu )
			  || exit 1;

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . "mem_k", $memk )
			  || exit 1;

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . "mem_per", $memp )
			  || exit 1;

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . "maxmem_k", $maxmem )
			  || exit 1;

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . "maxmem_per", $maxmemp )
			  || exit 1;

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . "vcpus", $vcpus )
			  || exit 1;

			$dbh->commit();
		};
		if ($@) {

			logEvent( 2, "Error 1 occured in analyse_vm_details(): $@" );

			exit 1;

		}

	}
}

sub analyse_vcpu_details {
	my ( $hypervisor, $vmname, @data ) = @_;

	# grab the first lot of vpus..
	my @vcpus = grep( /^VCPUs/, @data );
	my $vcpus = shift @vcpus;

	# grab the remainder if any..
	my @vcpus = grep( /^\s+\d+:\s/, @data );
	$vcpus = join( / /, $vcpus, @vcpus );

	$vcpus =~ s/\s+/ /g;
	$vcpus =~ s/^VCPUs\(sec\)//g;
	$vcpus =~ s/s//g;
	$vcpus =~ s/^ //g;
	$vcpus =~ s/ /,/g;
	$vcpus =~ s/://g;
	$vcpus =~ s/^,//g;
	$vcpus =~ s/,$//g;

	my @countvcpus = split( /,/, $vcpus );

	my $countvcpus = ( $#countvcpus + 1 ) / 2;

	#	my $statNamingDomain = "vcpu";
	#
	#	my $collectedInfoKeypairStorePath =
	#	  $clustername . "_" . $statNamingDomain . "_" . $vmname . "_";
	#

	my $collectedInfoKeypairStorePath =
	  "vcpu:" . $clustername . ":" . $hypervisor . ":" . $vmname . ":";

	eval {

		$dbh->begin_work();

		for ( my $loop = 0 ; $loop < $countvcpus ; $loop++ ) {

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . "cpu_$loop",
				@countvcpus[ ( $loop * 2 ) + 1 ] )
			  || exit 1;

		}

		$dbh->commit();
	};
	if ($@) {

		logEvent( 2, "Error 1 occured in analyse_vcpu_details(): $@" );

		exit 1;

	}

	return $countvcpus;
}

sub analyse_net_details {
	my ( $hypervisor, $vmname, @data ) = @_;

	# grab the first lot of vpus..
	my @net = grep( /^Net/, @data );

	for ( my $loop = 0 ; $loop < @net ; $loop++ ) {

		my $net = @net[$loop];

		$net =~ s/Net//g;

		$net =~ s/^\d+//g;
		my $varNetIndex = $&;

		$net =~ s/RX://g;

		$net =~ s/\S+bytes//i;
		( $& =~ /^\d+/ );
		my $varRxBytes = $&;

		$net =~ s/\S+pkts//i;
		( $& =~ /^\d+/ );
		my $varRxPkts = $&;

		$net =~ s/\S+err//i;
		( $& =~ /^\d+/ );
		my $varRxErrs = $&;

		$net =~ s/\S+drop//i;
		( $& =~ /^\d+/ );
		my $varRxDrop = $&;

		$net =~ s/\s+TX://g;

		$net =~ s/\S+bytes//i;
		( $& =~ /^\d+/ );
		my $varTxBytes = $&;

		$net =~ s/\S+pkts//i;
		( $& =~ /^\d+/ );
		my $varTxPkts = $&;

		$net =~ s/\S+err//i;
		( $& =~ /^\d+/ );
		my $varTxErrs = $&;

		$net =~ s/\S+drop//i;
		( $& =~ /^\d+/ );
		my $varTxDrop = $&;

		#		my $statNamingDomain = "net";
		#
		#		my $collectedInfoKeypairStorePath =
		#		  $clustername . "_" . $statNamingDomain . "_" . $vmname . "_";

		my $collectedInfoKeypairStorePath =
		  "net:" . $clustername . ":" . $hypervisor . ":" . $vmname . ":";

		my $keyPrefix = "NET" . $loop . "_";

		eval {

			$dbh->begin_work();

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . $keyPrefix . "INDEX",
				$varNetIndex )
			  || exit 1;

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . $keyPrefix . "RX_BYTES",
				$varRxBytes )
			  || exit 1;

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . $keyPrefix . "RX_PKTS",
				$varRxPkts )
			  || exit 1;

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . $keyPrefix . "RX_ERRS",
				$varRxErrs )
			  || exit 1;

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . $keyPrefix . "RX_DROP",
				$varRxDrop )
			  || exit 1;

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . $keyPrefix . "TX_BYTES",
				$varTxBytes )
			  || exit 1;

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . $keyPrefix . "TX_PKTS",
				$varTxPkts )
			  || exit 1;

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . $keyPrefix . "TX_ERRS",
				$varTxErrs )
			  || exit 1;

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . $keyPrefix . "TX_DROP",
				$varTxDrop )
			  || exit 1;

			$dbh->commit();
		};
		if ($@) {

			logEvent( 2, "Error 1 occured in analyse_net_details(): $@" );

			exit 1;

		}
	}
}

sub analyse_vbd_details {
	my ( $hypervisor, $vmname, @data ) = @_;

	# grab the first lot of vpus..
	my @vbd = grep( /^VBD/, @data );

	for ( my $loop = 0 ; $loop < @vbd ; $loop++ ) {

		my $vbd = @vbd[$loop];

		$vbd =~ s/VBD BlkBack\s+\d+//g;
		( $& =~ /\d+/ );
		my $varBlkBack = $&;

		$vbd =~ s/\[.+:.+\d+]//g;

		#( $& =~ /\d+/ );
		my $varVBDDeviceNumber = $&;

		$vbd =~ s/OO:\s+\d+//g;
		( $& =~ /\d+/ );
		my $varOO = $&;

		$vbd =~ s/RD:\s+\d+//g;
		( $& =~ /\d+/ );
		my $varRD = $&;

		$vbd =~ s/WR:\s+\d+//g;
		( $& =~ /\d+/ );
		my $varWR = $&;

		$vbd =~ s/RSECT:\s+\d+//g;
		( $& =~ /\d+/ );
		my $varRSECT = $&;

		$vbd =~ s/WSECT:\s+\d+//g;
		( $& =~ /\d+/ );
		my $varWSECT = $&;

		#		my $statNamingDomain = "vbd";
		#
		#		my $collectedInfoKeypairStorePath =
		#		  $clustername . "_" . $statNamingDomain . "_" . $vmname . "_";

		my $collectedInfoKeypairStorePath =
		  "vbd:" . $clustername . ":" . $hypervisor . ":" . $vmname . ":";

		my $keyPrefix = "VBD" . $loop . "_";

		eval {

			$dbh->begin_work();

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . $keyPrefix . "INDEX", $loop )
			  || exit 1;

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . $keyPrefix . "BLKBACK",
				$varBlkBack )
			  || exit 1;

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . $keyPrefix . "VBDDEVICENUMBER",
				$varVBDDeviceNumber
			) || exit 1;

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . $keyPrefix . "OO", $varOO )
			  || exit 1;

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . $keyPrefix . "RD", $varRD )
			  || exit 1;

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . $keyPrefix . "WR", $varWR )
			  || exit 1;

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . $keyPrefix . "RSECT",
				$varRSECT )
			  || exit 1;

			writeCollectedInfoKeypairToDatabase1(
				$collectedInfoKeypairStorePath . $keyPrefix . "WSECT",
				$varWSECT )
			  || exit 1;

			$dbh->commit();
		};
		if ($@) {

			logEvent( 2, "Error 1 occured in analyse_vbd_details(): $@" );

			exit 1;

		}
	}

}

sub getval {
	my ( $str, @lines ) = @_;

	my @output = grep( /$str/, @lines );
	chop( my $line = $output[0] );

	#chop $line;
	my ( $key, $result ) = split( /:/, $line );
	$result =~ s/^ //g;

	return $result;
}

sub getblock {
	my ( $delim, $start, $stop, @lines ) = @_;

	my @results;

	# find the right block to start
	my $finished = 0;

	for ( my $loop = 0 ; $loop <= $stop ; $loop++ ) {

		$finished = 0;
		my $found = 0;
		while ( @lines && !$found ) {
			if ( $loop > $stop ) {
				$finished = 1;
			}
			else {
				my $line = shift @lines;

				if ( $line =~ /$delim/ ) {

					$found = 1;
					if ( $loop >= $start ) {
						push @results, $line;
					}
				}
				else {
					if ( $loop >= $start ) {

						push @results, $line;
					}
				}
			}
		}
	}

	#pop @results;	# no no no!

	return @results;
}

sub cleandata {
	my $line = shift;

	$line =~ s/\s+/ /g;
	$line =~ s/^ //g;
	$line =~ s/ /,/g;
	return $line;
}

sub logEvent {    # method Version: 3
	my ( $eventType, $msg ) =
	  @_;         # event type: 1 - debug info, 2 - error, 3 - warning

	my ( $s, $usec ) = gettimeofday();    # get microseconds haha
	my $timestamp = localtime->strftime("%Y-%m-%d %H:%M:%S.") . ($usec);

	my $eventTypeDisplay = "";

	if ( ( $loggingLevel == 0 ) || ( $logOutput == 0 ) ) {
		return 0;
	}

	given ($eventType) {
		when (1) {
			$eventTypeDisplay = " Debug Info : ";

			if ( $loggingLevel == 1 ) {
				return 0;
			}

		}

		when (2) {
			$eventTypeDisplay = " !ERROR! : ";
		}

		when (3) {
			$eventTypeDisplay = " Warning : ";

			if ( $loggingLevel == 1 ) {
				return 0;
			}

		}

	}

	if ( ( $logOutput == 1 ) || ( $logOutput == 3 ) ) {

		print "[$$] $timestamp$eventTypeDisplay$msg\n";

	}

	if ( ( $logOutput == 2 ) || ( $logOutput == 3 ) ) {

		if ( open( LOGFILEHANDLE, ">>$logFileName" ) ) {
			print LOGFILEHANDLE
			  "[$thisModuleID][$$] $timestamp$eventTypeDisplay$msg\n";
			close LOGFILEHANDLE;

		}
		else {

			print "Can not open logfile $logFileName : $!\n";

		}

	}

}
