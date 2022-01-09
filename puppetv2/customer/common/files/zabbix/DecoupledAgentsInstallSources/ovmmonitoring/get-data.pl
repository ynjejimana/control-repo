#!/usr/bin/perl
#### Monitoring OVM Hypervisor
#### Version 2.30
#### Writen by: Phil Shead (pshead@harbourmsp.com)
#### Modifications: Premysl Botek (pbotek@harbourmsp.com)
##################################################################################

## compiler declarations, environment setup

use v5.10;
use strict;
use Config::Simple;
use Data::Dumper;
use DBI;
use Time::Piece;
use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);
use Switch;
use Date::Parse;
use Date::Format;

our $basedir          = "/srv/zabbix/scripts/ovmmonitoring";
our $logFileName      = "$basedir/log.txt";
our $databasefilename = "$basedir/ovmmonitoringdata.db";

my $loggingLevel = 2
  ; # 0 - no logging, 1 - log errors only, 2 - log everything (errors, warnings, debug info)
my $logOutput = 2
  ; # 1 - output to console, 2 - output to log file, 3 - output to both console and log file

our $confdir;

my $zpimZAgentPerf1TracingEnabled = 0;
my $zpimBaseDir                   = "/srv/zabbix/scripts/zpimonitoring";

my $zpimDatabase1FileName = "$zpimBaseDir/zpimonitoring.db";
my $zpimZAgentPerf1Tracing_OVMMonitoringGetDataAnchor1_GUID =
  'bffda3f5-762f-47eb-8db3-72384a15d18e';
my $zpimZAgentPerf1Tracing_OVMMonitoringGetDataAnchor1_TimeStamp0;

my $thisModuleID =
  "GET-DATA";    # just for log file record identification purposes

my $appMode = 0
  ; # 1 - get data from database, 2 - get data from log file (logged errors metadata), 3 - unused , 4 - get mount info, 5 - unused, 6 - pattern matched sum of deltas per sec

my $key1;
my $value1;
my $value2;
my $statName;
my $statParam1;
my $statParam2;
my $statNamingDomain;
my $last_completed_seq_no;
my $clusterName;
my $global_seq_no;
my $cluster_seq_no;

my $dbh;

my $invalidCommandLine = 1;

my $returnValue;


## program entry point
## program initialization

my $commandline = join " ", $0, @ARGV;
logEvent( 1, "Used command line: $commandline" );

$statName         = $ARGV[3];
$statNamingDomain = $ARGV[1];

switch ( uc( $ARGV[1] ) ) {

	case "HYPER" {

		if ( ( scalar @ARGV ) == 4 ) {

			#$key1    = $ARGV[0] . "_hyper_" . $ARGV[2] . "_" . $ARGV[3];
			$key1    = "hyper:" . $ARGV[0] . ":" . $ARGV[2] . ":" . $ARGV[3];
			$appMode = 1;
			$invalidCommandLine = 0;
		}

	}

	case "VM" {
		if ( ( scalar @ARGV ) == 4 ) {

		   #$key1               = $ARGV[0] . "_vm_" . $ARGV[2] . "_" . $ARGV[3];
			$key1    = "vm:" . $ARGV[0] . ":%:" . $ARGV[2] . ":" . $ARGV[3];
			$appMode = 1;
			$invalidCommandLine = 0;
		}
	}

	case "NET" {
		if ( ( scalar @ARGV ) == 4 ) {

			#$key1 = $ARGV[0] . "_net_" . $ARGV[2] . "_" . $ARGV[3];
			$key1 = "net:" . $ARGV[0] . ":%:" . $ARGV[2] . ":" . $ARGV[3];

			$appMode            = 1;
			$invalidCommandLine = 0;
		}
	}

	case "VBD" {
		if ( ( scalar @ARGV ) == 4 ) {

			#$key1 = $ARGV[0] . "_vbd_" . $ARGV[2] . "_" . $ARGV[3];
			$key1 = "vbd:" . $ARGV[0] . ":%:" . $ARGV[2] . ":" . $ARGV[3];

			$appMode            = 1;
			$invalidCommandLine = 0;
		}
	}

	case "VCPU" {
		if ( ( scalar @ARGV ) == 4 ) {

			#$key1 = $ARGV[0] . "_vcpu_" . $ARGV[2] . "_" . $ARGV[3];
			$key1 = "vcpu:" . $ARGV[0] . ":%:" . $ARGV[2] . ":" . $ARGV[3];

			$appMode            = 1;
			$invalidCommandLine = 0;
		}
	}

	case "PCPU" {
		if ( ( scalar @ARGV ) == 4 ) {

			#$key1 = $ARGV[0] . "_hyper_" . $ARGV[2] . "_xenmoninfo";
			$key1 = "hyper:" . $ARGV[0] . ":" . $ARGV[2] . ":xenmoninfo";

			$appMode            = 7;
			$invalidCommandLine = 0;
		}

	}

	case "METADATA" {

		if ( ( scalar @ARGV ) == 4 ) {

			#$key1    = $ARGV[0] . "_metadata_" . $ARGV[2] . "_" . $ARGV[3];
			$key1    = "metadata:" . $ARGV[0] . ":" . $ARGV[2] . ":" . $ARGV[3];
			$appMode = 1;
			$invalidCommandLine = 0;

			if ( uc( $ARGV[3] ) eq "SCRIPTSLOGFILEERRORS" ) {

				$appMode = 2;

			}

			if ( uc( $ARGV[2] ) eq "PMSDPS" )
			{    # pattern matched sum of deltas per sec
				$clusterName = $ARGV[0];
				$appMode     = 6;

			}
		}

	}

	case "MOUNT" {
		if ( ( scalar @ARGV ) == 5 ) {

			#$key1 = $ARGV[0] . "_hyper_" . $ARGV[2] . "_mountinfo";
			$key1 = "hyper:" . $ARGV[0] . ":" . $ARGV[2] . ":mountinfo";

			$statParam1 = $ARGV[3];
			$statParam2 = $ARGV[4];

			$invalidCommandLine = 0;
			$appMode            = 4;
		}

	}
}

if ($invalidCommandLine) {

	print <<USAGELABEL;
Invalid command line parameters
	
USAGE 1:	perl get-data.pl <clustername> <HYPER|VM|VCPU|NET|VBD|METADATA> <server> <statname>
RETURN 1:	value retrieved from database for the selected combination of parameters (Zabbix key)

USAGE 2:	perl get-data.pl <NULL> <METADATA> <NULL> <SCRIPTSLOGFILEERRORS> 
RETURN 2:	lists errors recorded in the .log file or returns returns "_none_". Log file is shared by all monitoring scripts for all hypervisors.
	
USAGE 3:	perl get-data.pl <clustername> <METADATA> <PMSDPS> <PATTERN> 
RETURN 3:	returns sum of delta/second values for items whose names are specified by pattern (simple SQL LIKE implementation)

USAGE 4:	perl get-data.pl <clustername> <MOUNT> <server> <mountname> <EXISTS|UTILP>
RETURN 4:	returns the mount information of specified type for specified mount on specified server

USAGE 5:	perl get-data.pl <clustername> <pCPU> <server> <pCPU_ID>
RETURN 5:	returns utilization of physical processor for hypervisor specified by server and pCPU_ID


LOGGING:	set $loggingLevel variable : 0 - no logging, 1 - log errors only, 2 - log everything (errors, warnings, debug info)

			set $logOutput variable : 1 - output to console, 2 - output to log file, 3 - output to both console and log file

NOTE:		do not use characters " _ ' in the command line
	
USAGELABEL

	exit 0;
}

## main execution block

# add anchor record to the internal monitoring db
zpimZAgentPerf1Entry(
	1,
	$zpimZAgentPerf1Tracing_OVMMonitoringGetDataAnchor1_GUID,
	\$zpimZAgentPerf1Tracing_OVMMonitoringGetDataAnchor1_TimeStamp0,
	$$,
	$commandline, 
	undef
);

switch ($appMode) {        # select program mode

	case 1 {
		$returnValue=fnGetDataFromDatabase();
	}

	case 2 {

		#fnGetDataFromLogFile();
		$returnValue=fnGetScriptLogFileErrorCount();
		print $returnValue;
	}

	case 4 {
		$returnValue=fnGetMountInfo();
	}

	case 6 {
		$returnValue=gnGetPMSDPS();    # get pattern matched sum of deltas per sec
	}

	case 7 {
		$returnValue=fnGetXenmonInfo();
	}
}

# remove anchor record from the internal monitoring db
zpimZAgentPerf1Entry(
	2,
	$zpimZAgentPerf1Tracing_OVMMonitoringGetDataAnchor1_GUID,
	\$zpimZAgentPerf1Tracing_OVMMonitoringGetDataAnchor1_TimeStamp0, $$,undef,
		$returnValue
);

## end - main execution block

##  program exit point	###########################################################################

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

		$sth->finish();

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

# parse the STDOUT dump of $df command, find specified mount name and return required info
sub checkMountExists {
	my ( $collectedDetails_dfcmd, $mountName ) = @_;

	my $result1                = 0;
	my @collectedDetails_dfcmd = split( /\n/, $collectedDetails_dfcmd );

	foreach my $item (@collectedDetails_dfcmd) {

		if ( $item =~ m/\s*$mountName$/ ) {

			$result1 = 1;
		}

	}

	return $result1;

}

# parse the STDOUT dump of $df command, find specified mount name and return required info
sub getMountUtilizationPercent {
	my ( $collectedDetails_dfcmd, $mountName ) = @_;

	my $result1                = -1;
	my @collectedDetails_dfcmd = split( /\n/, $collectedDetails_dfcmd );

	foreach my $item (@collectedDetails_dfcmd) {

		if ( $item =~ m/\s*$mountName$/ ) {

			$item =~ /(\w*)\S\s*\S*$/;
			$result1 = $1;

		}

	}

	return $result1;

}

# find the nearest preceding item to the item specified by $key, subtract their values and return result
sub getAvgDeltaPerSecondForStat {
	my ( $inKey, $inValue, $inTimestamp, $inSeqNumber ) = @_;

	my $result1 = 0;

	my $sql1 =
"SELECT DS_STATNAME,DS_VALUE,DT_TIMESTAMP FROM TA_COLLECTED_DATA WHERE DS_STATNAME='"
	  . $inKey
	  . "' AND DL_CLUSTER_SEQ_NUMBER="
	  . $inSeqNumber
	  . " ORDER BY DL_ID DESC LIMIT 1";

	logEvent( 1, "getAvgDeltaPerSecondForStat() Sql1: " . $sql1 );

	my $sth1 = $dbh->prepare($sql1);

	$sth1->execute();

	my @rowArray = $sth1->fetchrow_array();

	if ( defined( @rowArray[0] ) ) {

		$result1 =
		  ( $inValue - @rowArray[1] ) /
		  ( str2time($inTimestamp) - str2time( @rowArray[2] ) );

		logEvent( 1, "getAvgDeltaPerSecondForStat: adding " . $result1 );

	}

	$sth1->finish();

	return $result1;

}

sub fnGetDataFromDatabase {

	eval {

		# connect to database

		if ( !-f $databasefilename ) {
			logEvent( 2, "Database file $databasefilename does not exist" );
			exit 1;
		}

		$dbh = DBI->connect(
			"dbi:SQLite:dbname=$databasefilename",
			"", "", { RaiseError => 1 },
		);

		$dbh->begin_work();

		my $sql1 = <<DELIMITER1;
 
SELECT 

(
SELECT MAX(DL_CLUSTER_SEQ_NUMBER) FROM TA_COLLECTED_DATA
WHERE DS_STATNAME LIKE 'metadata:seqfooter:param1%'
) AS LAST_COMPLETED_CLUSTER_SEQ_NUMBER

DELIMITER1

		$sql1 =~ s/param1/$ARGV[0]/g
		  ; # parameters in complex parametrized sqlite queries do not work well. we do parameter replacement ourselves

		my $sth1 = $dbh->prepare($sql1);

		$sth1->execute()
		  ; # get cluster sequence number of the very last completed data gathering operation

		($cluster_seq_no) = $sth1->fetchrow_array();

		$sth1->finish();

		if ( !defined($cluster_seq_no) ) {
			$cluster_seq_no = 0;
		}

# query the very last cluster data gathering sequence - to avoid returning some stale data
		my $sql1 =
"SELECT DS_VALUE FROM TA_COLLECTED_DATA WHERE DS_STATNAME LIKE\"$key1\" AND DL_CLUSTER_SEQ_NUMBER=$cluster_seq_no";

		my $sth = $dbh->prepare($sql1);

		$sth->execute();

		($value1) = $sth->fetchrow_array();

		$dbh->commit();

		$sth->finish();

		$dbh->disconnect();

	};

	if ($@) {

		logEvent( 2, "Error 2 occured in fnGetDataFromDatabase(). $@" );
		exit 1;

	}

	if ( defined($value1) ) {
		print "$value1";
	}

	logEvent( 1, "Response : $value1" );
	
	
	return $value1;
	

}

#sub fnGetDataFromLogFile {    # return lines that contain !ERROR!
#	my $errorLines;
#
#	open( INPUT, $logFileName )
#
#	  || ( $errorLines = "Can not open logfile $logFileName : $!\n" );
#
#	while ( my $line = <INPUT> ) {
#
#		if ( $line =~ / !ERROR! / ) {
#
#			$errorLines = $errorLines . $line . "\n";
#
#		}
#	}
#
#	close(INPUT);
#
#	if ( !defined($errorLines) ) {
#
#		$errorLines = "_none_";
#
#	}
#
#	print $errorLines;
#
#	logEvent( 1, "Response : $errorLines;" );
#
#}

sub fnGetScriptLogFileErrorCount {    # method Version: 2
	my $returnValue              = -1;
	my $scriptLogFileErrorsCount = 0;

	if ( !open( INPUT, $logFileName ) ) {

		logEvent( 2, "Error 1 occured in fnGetScriptLogFileErrorCount(): $!" );

	}
	else {

		while ( my $line = <INPUT> ) {

			if ( $line =~ / !ERROR! / ) {

				$scriptLogFileErrorsCount++;

			}
		}

		close(INPUT);

		$returnValue = $scriptLogFileErrorsCount;

	}

	logEvent( 1, "Response : $returnValue" );

	return $returnValue;

}

sub fnGetMountInfo {

	eval {

		# connect to database

		if ( !-f $databasefilename ) {
			logEvent( 2, "Database file $databasefilename does not exist" );
			exit 1;
		}

		$dbh = DBI->connect(
			"dbi:SQLite:dbname=$databasefilename",
			"", "", { RaiseError => 1 },
		);

		$dbh->begin_work();

		my $sql1 = <<DELIMITER1;
 
SELECT 

(
SELECT MAX(DL_CLUSTER_SEQ_NUMBER) FROM TA_COLLECTED_DATA
WHERE DS_STATNAME LIKE 'metadata:seqfooter:param1%'
) AS LAST_COMPLETED_CLUSTER_SEQ_NUMBER

DELIMITER1

		$sql1 =~ s/param1/$ARGV[0]/g
		  ; # parameters in complex parametrized sqlite queries do not work well. we do parameter replacement ourselves

		my $sth1 = $dbh->prepare($sql1);

		$sth1->execute()
		  ; # get cluster sequence number of the very last completed data gathering operation

		($cluster_seq_no) = $sth1->fetchrow_array();

		$sth1->finish();

		if ( !defined($cluster_seq_no) ) {
			$cluster_seq_no = 0;
		}

# query the very last cluster data gathering sequence - to avoid returning some stale data
		my $sql1 =
"SELECT DS_VALUE FROM TA_COLLECTED_DATA WHERE DS_STATNAME LIKE\"$key1\" AND DL_CLUSTER_SEQ_NUMBER=$cluster_seq_no";

		my $sth = $dbh->prepare($sql1);

		$sth->execute();

		($value1) = $sth->fetchrow_array();

		$dbh->commit();

		$sth->finish();

		$dbh->disconnect();

	};

	if ($@) {

		logEvent( 2, "Error 2 occured in fnGetMountInfo(). $@" );
		exit 1;

	}

# parse the retrieved dump of "$ df" command, depending on what type of information was requested
	if ( defined($value1) ) {

		#print "$value1";

		switch ( uc($statParam2) ) {

			case "EXISTS" {
				$value2 = checkMountExists( $value1, $statParam1 );
				print($value2);
			}

			case "UTILP" {
				$value2 = getMountUtilizationPercent( $value1, $statParam1 );
				print($value2);
			}

		}

	}

	logEvent( 1, "Response : $value2" );
	
	return $value2;
	

}

# Gets sum of deltas per sec for items with pattern matched names:
# 1) looks at the two latest recorded values of specified item and returns delta
# 2) if pattern matches to name of more than one item, does the above for all matching items and returns the sum of their details
sub gnGetPMSDPS {

	eval {

		# connect to database

		if ( !-f $databasefilename ) {
			logEvent( 2, "Database file $databasefilename does not exist" );
			exit 1;
		}

		$dbh = DBI->connect(
			"dbi:SQLite:dbname=$databasefilename",
			"", "", { RaiseError => 1 },
		);

		logEvent( 1, "gnGetPMSDPS(), item pattern='$statName'" );

# get seq number of last fully completed hypervisor querying - just to ensure we don't work with incomplete data from an in-progress hypervisor querying

		my $sql1 = <<DELIMITER1;

SELECT 

(
SELECT MAX(DL_CLUSTER_SEQ_NUMBER) FROM TA_COLLECTED_DATA
WHERE DS_STATNAME LIKE 'metadata:seqfooter:param1%'
) AS LAST_CLUSTER_SEQ_NUMBER

DELIMITER1

		$sql1 =~ s/param1/$clusterName/g
		  ; # parameters in complex parametrized sqlite queries do not work well. we do parameter replacement ourselves

		logEvent( 1, "gnGetPMSDPS(): executing: $sql1" );

		my $sth1 = $dbh->prepare($sql1);

		$sth1->execute();

		($last_completed_seq_no) = $sth1->fetchrow_array();

		$sth1->finish();

		if ( !defined($last_completed_seq_no) ) {
			logEvent( 2,
				"gnGetPMSDPS(): DL_CLUSTER_SEQ_NUMBER does not exist" );
			exit 1;

		}

		# get list of stats whose names match required pattern
		my $sql1 =
"SELECT DS_STATNAME,DS_VALUE,DT_TIMESTAMP FROM TA_COLLECTED_DATA WHERE DL_CLUSTER_SEQ_NUMBER="
		  . $last_completed_seq_no
		  . " AND DS_STATNAME LIKE '"
		  . $statName . "'";

		#logEvent( 1, "appMode6 Sql3: " . $sql1 );

		my $sth = $dbh->prepare($sql1);

		$sth->execute();

		$value1 = 0;

# for each list item, find its nearest preceding item, subtract their values and add result to the sum
		while ( my @rowArray = $sth->fetchrow_array() ) {
			$value1 +=
			  getAvgDeltaPerSecondForStat( @rowArray[0], @rowArray[1],
				@rowArray[2], $last_completed_seq_no - 1 );
		}

		$sth->finish();

		$dbh->disconnect();

	};

	if ($@) {

		logEvent( 2, "Error 1 occured in gnGetPMSDPS(). $@" );
		exit 1;

	}

	my $rounded = sprintf( "%.0f", $value1 );
	print "$rounded";

	logEvent( 1, "Response : $rounded" );
	
	return $rounded;

}

sub fnGetXenmonInfo {    # get physical CPU info

	eval {

		# connect to database

		if ( !-f $databasefilename ) {
			logEvent( 2, "Database file $databasefilename does not exist" );
			exit 1;
		}

		$dbh = DBI->connect(
			"dbi:SQLite:dbname=$databasefilename",
			"", "", { RaiseError => 1 },
		);

		$dbh->begin_work();

		my $sql1 = <<DELIMITER1;
 
SELECT 

(
SELECT MAX(DL_CLUSTER_SEQ_NUMBER) FROM TA_COLLECTED_DATA
WHERE DS_STATNAME LIKE 'metadata:seqfooter:param1%'
) AS LAST_COMPLETED_CLUSTER_SEQ_NUMBER

DELIMITER1

		$sql1 =~ s/param1/$ARGV[0]/g
		  ; # parameters in complex parametrized sqlite queries do not work well. we do parameter replacement ourselves

		my $sth1 = $dbh->prepare($sql1);

		$sth1->execute()
		  ; # get cluster sequence number of the very last completed data gathering operation

		($cluster_seq_no) = $sth1->fetchrow_array();

		$sth1->finish();

		if ( !defined($cluster_seq_no) ) {
			$cluster_seq_no = 0;
		}

# query the very last cluster data gathering sequence - to avoid returning some stale data
		my $sql1 =
"SELECT DS_VALUE FROM TA_COLLECTED_DATA WHERE DS_STATNAME LIKE\"$key1\" AND DL_CLUSTER_SEQ_NUMBER=$cluster_seq_no";

		my $sth = $dbh->prepare($sql1);

		$sth->execute();

		($value1) = $sth->fetchrow_array();
		$dbh->commit();

		$sth->finish();

		$dbh->disconnect();

	};

	if ($@) {

		logEvent( 2, "Error 1 occured in fnGetXenmonInfo(). $@" );
		exit 1;

	}

	if ( defined($value1) ) {

		my @array1 = split( /\n\n/, $value1 );
		logEvent( 1, "fnGetPCPUUtil array length=" . scalar @array1 );
		my @array2 = split( /:/, @array1[ $ARGV[3] ] );
		if ( defined( @array2[1] ) ) {
			$value2 = sprintf( "%.2f", ( 100 - @array2[1] ) );
		}
		else {
			$value2 = "";

		}
		print "$value2";

	}

	logEvent( 1, "Response : $value2" );
	
	return $value2;

}

################# - Zabbix Proxy Internal Monitoring - Common API Library ver. seq. #6

# zpimZAgentPerf1Entry: add/remove anchor record to/from the proxy internal monitoring db
# input/output parameters:
# param1: 1 - add, 2 - remove
# param2: anchor guid
# param3: reference to a timestamp that keeps time when anchor was inserted (measuring time lapsed). third parameter must be a reference - sub is going to write to it.
# param4: current process ID - identifies session ($$ gets the current process ID)
# param5: additional session parameters (command line)

sub zpimZAgentPerf1Entry {
	my ( $actionId, $functinalityGUID, $anchorTimestampRef, $sessionId, $dsVal1,
		$dsVal2
	  ) # $anchorTimestampRef is a reference - for further variable modifications
	  = # $actionId: 1 - add functionality section session anchor, 2 - remove functionality section anchor
	  @_;

	my $returnValue = 0;
	my $zpimDatabase1DBH;
	my $zpimSth1;
	my $zpimSql1;

## test if tracing is enabled
	if ( $zpimZAgentPerf1TracingEnabled != 1 ) {
		return $returnValue;
	}

	logEvent( 1, "zpimDatabase1FileName: $zpimDatabase1FileName" );

## test if internal monitoring database exists
	if ( !( -f $zpimDatabase1FileName ) ) {
		logEvent( 2, "Error 1 in zpimZAgentPerf1Entry(): $@" );
		return $returnValue;
	}

## open internal monitoring database
	eval {

		$zpimDatabase1DBH = DBI->connect(
			"dbi:SQLite:dbname=$zpimDatabase1FileName",
			"", "", { RaiseError => 1 },
		);

	};

	if ($@) {
		logEvent( 2, "Error 2 in zpimZAgentPerf1Entry(): $@" );
		return $returnValue;
	}

#### do the work

	if ( $actionId == 1 ) {    ### add a fresh anchor record

		eval {

			# delete possibly existing stale record
			$zpimSql1 = <<DELIMITER1;
		
DELETE FROM TA_ZAGENT_PERF_1
WHERE DS_FUNCTIONALITY_GUID=? AND DS_SESSION_ID=? 	
		
DELIMITER1

			$zpimSth1 = $zpimDatabase1DBH->prepare($zpimSql1);

			$zpimSth1->execute( $functinalityGUID, $sessionId );

			# insert fresh record
			$zpimSql1 = <<DELIMITER1;
		
INSERT INTO TA_ZAGENT_PERF_1 (DL_ANCHOR_STATUS,DS_FUNCTIONALITY_GUID,DS_SESSION_ID,DS_VAL1) 
VALUES (1,?,?,?)	
		
DELIMITER1

			$zpimSth1 = $zpimDatabase1DBH->prepare($zpimSql1);

			$zpimSth1->execute( $functinalityGUID, $sessionId, $dsVal1 );

		};

		if ($@) {
			logEvent( 2, "Error 3 in zpimZAgentPerf1Entry(): $@" );
			return $returnValue;
		}

		$$anchorTimestampRef =
		  int( gettimeofday() * 1000 )
		  ; # modify dereferenced global variable - get current timestamp of time when a new anchor was created

	}

	if ( $actionId == 2 ) {    ### remove anchor record

		my $anchorLapsedTime =
		  int( gettimeofday() * 1000 ) - $$anchorTimestampRef;
		eval {

## update status of anchor record (2=completed)
			$zpimSql1 = <<DELIMITER1;
				
UPDATE TA_ZAGENT_PERF_1 SET DL_ANCHOR_STATUS=2, DL_ANCHOR_DURATION=?, DS_VAL2=?  
WHERE DS_FUNCTIONALITY_GUID=? AND DS_SESSION_ID=? 
		
DELIMITER1

			$zpimSth1 = $zpimDatabase1DBH->prepare($zpimSql1);

			$zpimSth1->execute( $anchorLapsedTime, $dsVal2, $functinalityGUID,
				$sessionId );
		};

		if ($@) {
			logEvent( 2, "Error 4 in zpimZAgentPerf1Entry(): $@" );
			return $returnValue;
		}

	}

### close internal monitoring database
	eval {

		undef $zpimDatabase1DBH;

	};
	if ($@) {

		logEvent( 2, "Error 10 in zpimZAgentPerf1Entry(): $@" );
		return $returnValue;
	}

}

################# - EOF - Zabbix Proxy Internal Monitoring - Common API Library

