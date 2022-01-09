#!/usr/bin/perl
#### Utilities Monitoring V1 (Zabbix automated extended monitoring utility)
#### Version 1.45
#### Written by: Premysl Botek (premysl.botek@lab.com)
##################################################################################
#### Execution Requirements:
#### * All non-default Perl modules listed as "use" from section "pragmas ..." below (i.e $ yum install perl-Time-HiRes perl-Net-SNMP, $ cpan Config::Std etc.)
##################################################################################
#
#
#

## compiler declarations, environment setup

use v5.10;
use strict;
use Config::Simple;
use Data::Dumper;

#use Net::OpenSSH;
use Time::Piece;
use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);
use DBI;
use Switch;
use Sys::Hostname;

# DEPENDENT SETTINGS (values need to be reverified/set correctly during each installation - for this script to work and be integrated with the rest of functionality)

my $loggingLevel = 1
  ; # 0 - no logging, 1 - log errors only, 2 - log everything (errors, warnings, debug info)
my $logOutput = 2
  ; # 1 - output to console, 2 - output to log file, 3 - output to both console and log file

our $basedir          = "/srv/zabbix/scripts/utilitiesmonitoring";
our $logFileName      = "$basedir/log.txt";
our $databasefilename = "$basedir/utilitiesmonitoringdata.db";

my $appmode2_CronDataCollectionInterval =
  300;    # [seconds] - used for calculation of throughput etc.

## End - DEPENDENT SETTINGS

my $thisModuleID =
  "COLLECT-POSTFIX-STATS";    # just for log file record identification purposes

my $global_seq_no;
my $machine_seq_no;

my $stderr1;

my $zabbix_sender = "zabbix_sender";

my $globMachineName;
# my $globMachineUsername = 'root';
# my $globMachinePassword = 'xxxxx';

my $localDBH;

my $appMode = 0;

my $invalidCommandLine = 1;

my $appmode2_postfixLogFilename;
my $appmode2_postfixTrapReference;
my @appmode2_postfixStatsArray;    #contains whole log analyze file
my @appmode2_postfixStatsArray_Section1
  ;    #contains only section "Grand Totals" from log analyze report file

my @appmode2_postfixStatsArray_Section2
  ; # contains only last section from the log analyze report file (everything after "message deferral detail...")

my $encounteredErrors = 0;

# self reflection

hostname =~ /^(.*?)\..*/
  ; # get system hostname and clean out possible domain (clean everything after first dot, inclusive)
my $thisMachineHostname = $1;

## program entry point

main();

##  program exit point	###########################################################################

sub main {

	## program initialization

	my $commandline = join " ", $0, @ARGV;
	logEvent( 1, "Used command line: $commandline" );

	if ( scalar(@ARGV) < 1 ) {
		$invalidCommandLine = 1;
	}
	else {

		$invalidCommandLine = 1;

		given ( uc( $ARGV[0] ) ) {

			#
			#			when ("1") {
			#
			#				if ( scalar(@ARGV) >= 2 ) {
			#
			#					$globMachineName    = $ARGV[1];
			#					$appMode            = 1;
			#					$invalidCommandLine = 0;
			#
			#				}
			#
			#			}

			when ("2") {

				if ( scalar(@ARGV) >= 4 ) {

					$globMachineName               = $ARGV[1];
					$appmode2_postfixLogFilename   = $ARGV[2];
					$appmode2_postfixTrapReference = $ARGV[3];
					$appMode            = 2;    # harvest postfix log
					$invalidCommandLine = 0;

				}

			}

		}

	}

	if ( $invalidCommandLine == 1 ) {

		print <<USAGELABEL;
Invalid command line parameters
	
USAGE:		perl get-hypervisor-stats.pl <hypervisor>

RETURNS:	either nothing or an error message
	
LOGGING:	set $loggingLevel variable : 0 - no logging, 1 - log errors only, 2 - log everything (errors, warnings, debug info)

			set $logOutput variable : 1 - output to console, 2 - output to log file, 3 - output to both console and log file
	
USAGELABEL

		exit 0;
	}

# connect to database
#
#	if ( !-f $databasefilename ) {
#		logEvent( 2, "Database file $databasefilename does not exist" );
#		exit 1;
#	}
#
#	$localDBH = DBI->connect(
#		"dbi:SQLite:dbname=$databasefilename",
#		"", "", { RaiseError => 1 },
#	  )
#
#	  || { logEvent( 2, "Can't connect to database: $DBI::errstr" )
#		  && exit 1 };
#
#	# maintain TA_COLLECTED_DATA table (delete outdated records)
#	maintainDataRetention() or exit 1;
#
#	$localDBH->begin_work();
#
#	my $sql1 = <<DELIMITER1;
#
#SELECT
#
#(
#SELECT MAX(DL_GLOBAL_SEQ_NUMBER) FROM TA_COLLECTED_DATA
#) AS LAST_GLOBAL_SEQ_NO
#,
#(
#SELECT MAX(DL_CLUSTER_SEQ_NUMBER) FROM TA_COLLECTED_DATA
#WHERE DS_STATNAME LIKE 'metadata:seqheader:param1%'
#) AS LAST_CLUSTER_SEQ_NUMBER
#
#DELIMITER1
#
#	$sql1 =~ s/param1/$globMachineName/g
#	  ; # parameters in complex parametrized sqlite queries do not work well. we do parameter replacement ourselves
#
#	my $sth1 = $localDBH->prepare($sql1);
#
#	$sth1->execute();
#
#	( $global_seq_no, $machine_seq_no ) = $sth1->fetchrow_array();
#
#	$sth1->finish();
#
#	if ( !defined($global_seq_no) ) {
#		$global_seq_no = 0;
#	}
#
#	if ( !defined($machine_seq_no) ) {
#		$machine_seq_no = 0;
#	}
#
#	$global_seq_no++;
#	$machine_seq_no++;
#
#	my $sql1 =
#"INSERT INTO TA_COLLECTED_DATA (DL_GLOBAL_SEQ_NUMBER,DL_CLUSTER_SEQ_NUMBER,DS_STATNAME) VALUES (?,?,?)";
#
#	my $sth1 = $localDBH->prepare($sql1);
#
#	$sth1->execute( $global_seq_no, $machine_seq_no,
#		"metadata:seqheader:" . $globMachineName );
#
#	$localDBH->commit();

## main execution block
	#
	#foreach my $hypervisor (@hypervisors) {
	#	$total_cpu_usage       = 0;
	#	$cpu_subscription      = 0;
	#	$subscribed_cpus_count = 0;
	#
	#	get_postfix_info( $hypervisor, $globMachineName, $monitoruser );
	#}

	given ($appMode) {

		#		when (1) {
		#
		#			get_postfix_info($globMachineName);
		#
		#		}

		when (2) {
			fnHarvestPostfixLogfile();

		}

	}

## end - main execution block

#
#	my $sql1 =
#"INSERT INTO TA_COLLECTED_DATA (DL_GLOBAL_SEQ_NUMBER,DL_CLUSTER_SEQ_NUMBER,DS_STATNAME) VALUES (?,?,?)";
#
#	my $sth1 = $localDBH->prepare($sql1);
#
#	$sth1->execute( $global_seq_no, $machine_seq_no,
#		"metadata:seqfooter:" . $globMachineName );
#
#	# disconnect from database
#	$localDBH->disconnect()
#	  || { logEvent( 2, "Can't disconnect from database: $DBI::errstr" )
#		  && exit 1 };

}

sub fnHarvestPostfixLogfile {

	#my ($machine) = @_;
	my $subResult        = 0;
	my $tmpWorkingTMPDir =
	  "/tmp/utilitiesmonitoring/postfix-logfile-data/$globMachineName";
	my $tmpVal1;
	my $tmpVal2;

	logEvent( 1, "Harvesting Postfix machine $globMachineName" );

### prepare working temp directory

	my $tmpCmd1 =
"find $tmpWorkingTMPDir -type 'f' | grep -v 'postfix-logfile.offset' | xargs rm";

	my ( $execSubResult, $execResultCode, $execStdErr, @execOutput ) =
	  executeShellCommand($tmpCmd1);

	my ( $execSubResult, $execResultCode, $execStdErr, @execOutput ) =
	  executeShellCommand("mkdir -p $tmpWorkingTMPDir");

	$encounteredErrors = 0;    # ignore previous errors

### fetch log file

	my $tmpCmd1 =
"scp $globMachineName:$appmode2_postfixLogFilename $tmpWorkingTMPDir/postfix-logfile";

	logEvent( 1, "Fetching log file: $tmpCmd1" );

	my ( $execSubResult, $execResultCode, $execStdErr, @execOutput ) =
	  executeShellCommand($tmpCmd1);
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

### tail log file: extract only the tail that has not previously been analysed

	my $tmpCmd1 =
"/usr/sbin/logtail -f$tmpWorkingTMPDir/postfix-logfile > $tmpWorkingTMPDir/postfix-logfile.tail";
	logEvent( 1, "Getting log file tail: $tmpCmd1" );

	my ( $execSubResult, $execResultCode, $execStdErr, @execOutput ) =
	  executeShellCommand($tmpCmd1);
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

### run log file analyzer

	my $tmpCmd1 =
"perl $basedir/pflogsumm.pl $tmpWorkingTMPDir/postfix-logfile.tail -h 0 -u 0 > $tmpWorkingTMPDir/postfix-logfile.tail.analyzed";

#	my $tmpCmd1 =
#"perl $basedir/pflogsumm.pl $tmpWorkingTMPDir/postfix-logfile -h 0 -u 0 > $tmpWorkingTMPDir/postfix-logfile.tail.analyzed";

	logEvent( 1, "Analyzing log file tail: $tmpCmd1" );

	my ( $execSubResult, $execResultCode, $execStdErr, @execOutput ) =
	  executeShellCommand($tmpCmd1);
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

### send stats to Zabbix trapper

	my $zabbixProxy = "localhost";
	my $zabbixHost  = $thisMachineHostname;

	logEvent( 1, "Sending stats to Zabbix" );

	appmode2_loadTextFileToArray1(
		"$tmpWorkingTMPDir/postfix-logfile.tail.analyzed");

	chomp(@appmode2_postfixStatsArray);

	#print Dumper(@appmode2_postfixStatsArray);

	(@appmode2_postfixStatsArray_Section1) =
	  appmode2_extractArraySection_SearchType1( '^Grand Totals$',
		'^Per-Hour Traffic Summary$' );

## pf_received

	$tmpVal1 =
	  appmode2_fetchStatValue_SearchMethod1( "received",
		@appmode2_postfixStatsArray_Section1 );

	sendTrapToZabbix( $zabbixProxy, $zabbixHost,
		$appmode2_postfixTrapReference . '_pf_received', $tmpVal1 );

## pf_received_messages_per_sec (!depends on the previous stat)

	$tmpVal2 =
	  $tmpVal1 / $appmode2_CronDataCollectionInterval;    # compute per second

	sendTrapToZabbix( $zabbixProxy, $zabbixHost,
		$appmode2_postfixTrapReference . '_pf_received_messages_per_sec',
		$tmpVal2 );

## pf_delivered

	$tmpVal1 =
	  appmode2_fetchStatValue_SearchMethod1( "delivered",
		@appmode2_postfixStatsArray_Section1 );

	sendTrapToZabbix( $zabbixProxy, $zabbixHost,
		$appmode2_postfixTrapReference . '_pf_delivered', $tmpVal1 );

## pf_delivered_messages_per_sec (!depends on the previous stat)

	$tmpVal2 =
	  $tmpVal1 / $appmode2_CronDataCollectionInterval;    # compute per second

	sendTrapToZabbix( $zabbixProxy, $zabbixHost,
		$appmode2_postfixTrapReference . '_pf_delivered_messages_per_sec',
		$tmpVal2 );

## pf_forwarded

	$tmpVal1 =
	  appmode2_fetchStatValue_SearchMethod1( "forwarded",
		@appmode2_postfixStatsArray_Section1 );

	sendTrapToZabbix( $zabbixProxy, $zabbixHost,
		$appmode2_postfixTrapReference . '_pf_forwarded', $tmpVal1 );

## pf_deferred

	$tmpVal1 =
	  appmode2_fetchStatValue_SearchMethod1( "deferred",
		@appmode2_postfixStatsArray_Section1 );

	sendTrapToZabbix( $zabbixProxy, $zabbixHost,
		$appmode2_postfixTrapReference . '_pf_deferred', $tmpVal1 );

## pf_bounced

	$tmpVal1 =
	  appmode2_fetchStatValue_SearchMethod1( "bounced",
		@appmode2_postfixStatsArray_Section1 );

	sendTrapToZabbix( $zabbixProxy, $zabbixHost,
		$appmode2_postfixTrapReference . '_pf_bounced', $tmpVal1 );

## pf_rejected

	$tmpVal1 =
	  appmode2_fetchStatValue_SearchMethod1( "rejected",
		@appmode2_postfixStatsArray_Section1 );

	sendTrapToZabbix( $zabbixProxy, $zabbixHost,
		$appmode2_postfixTrapReference . '_pf_rejected', $tmpVal1 );

## pf_reject_warnings

	$tmpVal1 = appmode2_fetchStatValue_SearchMethod1( "reject warnings",
		@appmode2_postfixStatsArray_Section1 );

	sendTrapToZabbix( $zabbixProxy, $zabbixHost,
		$appmode2_postfixTrapReference . '_pf_reject_warnings', $tmpVal1 );

## pf_held

	$tmpVal1 =
	  appmode2_fetchStatValue_SearchMethod1( "held",
		@appmode2_postfixStatsArray_Section1 );

	sendTrapToZabbix( $zabbixProxy, $zabbixHost,
		$appmode2_postfixTrapReference . '_pf_held', $tmpVal1 );

## pf_discarded

	$tmpVal1 =
	  appmode2_fetchStatValue_SearchMethod1( "discarded",
		@appmode2_postfixStatsArray_Section1 );

	sendTrapToZabbix( $zabbixProxy, $zabbixHost,
		$appmode2_postfixTrapReference . '_pf_discarded', $tmpVal1 );

## pf_received_bytes

	$tmpVal1 = appmode2_fetchStatValue_SearchMethod1( "bytes received",
		@appmode2_postfixStatsArray_Section1 );

	$tmpVal1 =~ /\s*(\d*)\s*(\S*)/;

	if ( $2 ne "" )
	{    # multiply by 1024 if the value has sign 'k' attached to it (kilobytes)

		if ( $2 eq "k" ) {
			$tmpVal1 = $tmpVal1 * 1024;
		}
		else {

			$tmpVal1 = -1;

			$encounteredErrors++;

			logEvent( 2,
"Error 1 in fnHarvestPostfixLogfile(): unknown unit sign encountered: $tmpVal1"
			);

		}

	}

	sendTrapToZabbix( $zabbixProxy, $zabbixHost,
		$appmode2_postfixTrapReference . '_pf_received_bytes', $tmpVal1 );

## pf_received_throughput (!depends on the previous stat)

	$tmpVal2 =
	  int( $tmpVal1 / $appmode2_CronDataCollectionInterval )
	  ;    # get received bytes per second

	sendTrapToZabbix( $zabbixProxy, $zabbixHost,
		$appmode2_postfixTrapReference . '_pf_received_throughput', $tmpVal2 );

## pf_delivered_bytes

	$tmpVal1 = appmode2_fetchStatValue_SearchMethod1( "bytes delivered",
		@appmode2_postfixStatsArray_Section1 );

	$tmpVal1 =~ /\s*(\d*)\s*(\S*)/;

	if ( $2 ne "" )
	{    # multiply by 1024 if the value has sign 'k' attached to it (kilobytes)

		if ( $2 eq "k" ) {
			$tmpVal1 = $tmpVal1 * 1024;
		}
		else {

			$tmpVal1 = -1;

			$encounteredErrors++;

			logEvent( 2,
"Error 2 in fnHarvestPostfixLogfile(): unknown unit sign encountered: $tmpVal1"
			);

		}
	}

	sendTrapToZabbix( $zabbixProxy, $zabbixHost,
		$appmode2_postfixTrapReference . '_pf_delivered_bytes', $tmpVal1 );

## pf_delivered_throughput (!depends on the previous stat)

	$tmpVal2 =
	  int( $tmpVal1 / $appmode2_CronDataCollectionInterval )
	  ;    # get delivered bytes per second

	sendTrapToZabbix( $zabbixProxy, $zabbixHost,
		$appmode2_postfixTrapReference . '_pf_delivered_throughput', $tmpVal2 );

## pf_message_deferral_detail

	$tmpVal2 = 'none';

	if (
		appmode2_findLineInArray( 'message deferral detail: none',
			@appmode2_postfixStatsArray ) == 0
	  )
	{

		$tmpVal2 =
		  appmode2_ExtractBlockStatDetail_SearchMethod1(
			'message deferral detail',
			@appmode2_postfixStatsArray )

	}
	sendTrapToZabbix(
		$zabbixProxy, $zabbixHost,
		$appmode2_postfixTrapReference . '_pf_message_deferral_detail',
		escapeForBashCMDLineParameter($tmpVal2)
	);

## pf_message_bounce_detail

	$tmpVal2 = 'none';

	if (
		appmode2_findLineInArray( 'message bounce detail (by relay): none',
			@appmode2_postfixStatsArray ) == 0
	  )
	{

		$tmpVal2 =
		  appmode2_ExtractBlockStatDetail_SearchMethod1(
			'message bounce detail (by relay)',
			@appmode2_postfixStatsArray )

	}

	sendTrapToZabbix(
		$zabbixProxy, $zabbixHost,
		$appmode2_postfixTrapReference . '_pf_message_bounce_detail',
		escapeForBashCMDLineParameter($tmpVal2)
	);

## pf_message_reject_detail

	$tmpVal2 = 'none';

	if (
		appmode2_findLineInArray( 'message reject detail: none',
			@appmode2_postfixStatsArray ) == 0
	  )
	{

		$tmpVal2 =
		  appmode2_ExtractBlockStatDetail_SearchMethod1(
			'message reject detail',
			@appmode2_postfixStatsArray )

	}

	sendTrapToZabbix(
		$zabbixProxy, $zabbixHost,
		$appmode2_postfixTrapReference . '_pf_message_reject_detail',
		escapeForBashCMDLineParameter($tmpVal2)
	);

## pf_message_reject_warning_detail

	$tmpVal2 = 'none';

	if (
		appmode2_findLineInArray( 'message reject warning detail: none',
			@appmode2_postfixStatsArray ) == 0
	  )
	{

		$tmpVal2 =
		  appmode2_ExtractBlockStatDetail_SearchMethod1(
			'message reject warning detail',
			@appmode2_postfixStatsArray )

	}

	sendTrapToZabbix(
		$zabbixProxy, $zabbixHost,
		$appmode2_postfixTrapReference . '_pf_message_reject_warning_detail',
		escapeForBashCMDLineParameter($tmpVal2)
	);

## pf_message_hold_detail

	$tmpVal2 = 'none';

	if (
		appmode2_findLineInArray( 'message hold detail: none',
			@appmode2_postfixStatsArray ) == 0
	  )
	{

		$tmpVal2 =
		  appmode2_ExtractBlockStatDetail_SearchMethod1( 'message hold detail',
			@appmode2_postfixStatsArray )

	}

	sendTrapToZabbix(
		$zabbixProxy, $zabbixHost,
		$appmode2_postfixTrapReference . '_pf_message_hold_detail',
		escapeForBashCMDLineParameter($tmpVal2)
	);

## pf_message_discard_detail

	$tmpVal2 = 'none';

	if (
		appmode2_findLineInArray( 'message discard detail: none',
			@appmode2_postfixStatsArray ) == 0
	  )
	{

		$tmpVal2 =
		  appmode2_ExtractBlockStatDetail_SearchMethod1(
			'message discard detail',
			@appmode2_postfixStatsArray )

	}

	sendTrapToZabbix(
		$zabbixProxy, $zabbixHost,
		$appmode2_postfixTrapReference . '_pf_message_discard_detail',
		escapeForBashCMDLineParameter($tmpVal2)
	);

## pf_smtp_delivery_failures

	$tmpVal2 = 'none';

	if (
		appmode2_findLineInArray( 'smtp delivery failures: none',
			@appmode2_postfixStatsArray ) == 0
	  )
	{

		$tmpVal2 =
		  appmode2_ExtractBlockStatDetail_SearchMethod1(
			'smtp delivery failures',
			@appmode2_postfixStatsArray )

	}

	sendTrapToZabbix(
		$zabbixProxy, $zabbixHost,
		$appmode2_postfixTrapReference . '_pf_smtp_delivery_failures',
		escapeForBashCMDLineParameter($tmpVal2)
	);

## pf_warning_detail

	$tmpVal2 = 'none';

	if (
		appmode2_findLineInArray( 'Warnings: none',
			@appmode2_postfixStatsArray ) == 0
	  )
	{

		$tmpVal2 =
		  appmode2_ExtractBlockStatDetail_SearchMethod1( 'Warnings',
			@appmode2_postfixStatsArray )

	}

	sendTrapToZabbix(
		$zabbixProxy, $zabbixHost,
		$appmode2_postfixTrapReference . '_pf_warning_detail',
		escapeForBashCMDLineParameter($tmpVal2)
	);

## pf_fatal_errors

	$tmpVal2 = 'none';

	if (
		appmode2_findLineInArray( 'Fatal Errors: none',
			@appmode2_postfixStatsArray ) == 0
	  )
	{

		$tmpVal2 =
		  appmode2_ExtractBlockStatDetail_SearchMethod1( 'Fatal Errors',
			@appmode2_postfixStatsArray )

	}

	sendTrapToZabbix(
		$zabbixProxy, $zabbixHost,
		$appmode2_postfixTrapReference . '_pf_fatal_errors',
		escapeForBashCMDLineParameter($tmpVal2)
	);

## pf_panics

	$tmpVal2 = 'none';

	if ( appmode2_findLineInArray( 'Panics: none', @appmode2_postfixStatsArray )
		== 0 )
	{

		$tmpVal2 =
		  appmode2_ExtractBlockStatDetail_SearchMethod1( 'Panics',
			@appmode2_postfixStatsArray )

	}

	sendTrapToZabbix(
		$zabbixProxy, $zabbixHost,
		$appmode2_postfixTrapReference . '_pf_panics',
		escapeForBashCMDLineParameter($tmpVal2)
	);

## pf_master_daemon_messages

	$tmpVal2 = 'none';

	if (
		appmode2_findLineInArray( 'Master daemon messages: none',
			@appmode2_postfixStatsArray ) == 0
	  )
	{

		$tmpVal2 =
		  appmode2_ExtractBlockStatDetail_SearchMethod1(
			'Master daemon messages',
			@appmode2_postfixStatsArray )

	}

	sendTrapToZabbix(
		$zabbixProxy, $zabbixHost,
		$appmode2_postfixTrapReference . '_pf_master_daemon_messages',
		escapeForBashCMDLineParameter($tmpVal2)
	);

## pf_log_sampling_interval

	sendTrapToZabbix(
		$zabbixProxy, $zabbixHost,
		$appmode2_postfixTrapReference . '_pf_log_sampling_interval',
		$appmode2_CronDataCollectionInterval
	);

### finalize sub

	return $subResult;

}

sub sendTrapToZabbix {
	my ( $zabbix_proxy, $zabbixHost, $key, $msg ) = @_;
	my $result = 0;
	my $returnBuff;
	my $zabbix_port = "10051";

	# Start the final command string
	my $cmd =
	    $zabbix_sender
	  . " --zabbix-server "
	  . $zabbix_proxy
	  . " --port "
	  . $zabbix_port
	  . " --host "
	  . $zabbixHost
	  . " --key $key --value";
	$cmd = $cmd . " \"" . $msg . "\"";

	logEvent( 1, "SendTrapToZabbix() cmd: $cmd" );

	$returnBuff = `$cmd`;

	chomp($returnBuff);

	logEvent( 1, "SendTrapToZabbix() : return info: $returnBuff" );

	$returnBuff =~ /.*Failed\s+([0-9])/;
	if ( $1 > 0 || !$returnBuff ) {

		logEvent( 2,
"Error 1 in SendTrapToZabbix(): command: $cmd, returned: $returnBuff"
		);

	}
	else {

		#logEvent( 1, "Sending trap was successful." );

		$result = 1;

	}

	return $result;
}

#sub get_postfix_info {
#	my ($machine) = @_;
#
#	logEvent( 1, "Querying Postfix machine $machine" );
#
#	my $cmd;
#
#	$ssh_pipe = Net::OpenSSH->new(
#		$machine,
#		master_opts => [
#			-o => "StrictHostKeyChecking=no",
#			-o => "ConnectTimeout $remoteCommandConnectionTimeout"
#		],
#		user => $globMachineUsername,
#
#		password => $globMachinePassword
#		,    # use this if you do not want passwordless authentication
#		strict_mode => 0,
#
#	);
#
#	$ssh_pipe->error
#	  &&{
#		logEvent( 2,
#			"SSH connection to Postfix machine $machine failed: "
#			  . $ssh_pipe->error )
#		  && exit 1
#	  };
#
#	# run remote cmd
#	if (
#		(
#			$remoteCmd_execResult_postqueue,
#			@remoteCmd_collectedDetails_postqueue
#		)
#		= exec_remote_command(
#			"$remoteCmd_postqueue;"
#
#		)
#	  )
#	{
#		$remoteCmd_execResult_postqueue = 0;
#		ParseAndSaveDetails_postqueue( $machine,
#			@remoteCmd_collectedDetails_postqueue );
#	}
#	else {
#		$remoteCmd_execResult_postqueue = 1;
#		$failedRemoteCommandsCount++;
#	}
#
#}

#sub ParseAndSaveDetails_postqueue {
#	my ( $machine, @collectedDetails ) = @_;
#	my $returnValue                   = 0;
#	my $errorCounter                  = 0;
#	my $collectedInfoKeypairStorePath = "payload:$machine:postfix";
#
#	my $postfix_queue_length = @collectedDetails[0];
#
#	eval {
#
#		$localDBH->begin_work();
#
#		if (
#			!writeCollectedInfoKeypairToDatabase1(
#				"$collectedInfoKeypairStorePath:queue_length",
#				$postfix_queue_length
#			)
#		  )
#		{
#
#			$errorCounter++;
#
#		}
#
#		if ( $errorCounter == 0 ) {
#			$localDBH->commit();
#		}
#		else {
#
#			$localDBH->rollback();
#
#		}
#
#	};
#	if ($@) {
#
#		logEvent( 2, "Error 1 occured in ParseAndSaveDetails_postqueue(): $@" );
#
#		exit 1;
#
#	}
#}

sub writeCollectedInfoKeypairToDatabase1 {  # needs to work within a transaction

	my ( $statname1, $value1 ) = @_;
	my $subresult = 0;

	eval {

		my $sql1 =
"INSERT INTO TA_COLLECTED_DATA(DS_STATNAME,DS_VALUE, DL_GLOBAL_SEQ_NUMBER,DL_CLUSTER_SEQ_NUMBER) VALUES (\"$statname1\",\"$value1\",$global_seq_no,$machine_seq_no)";

		$localDBH->do($sql1);

		$subresult = 1;

	};

	if ($@) {

		logEvent( 2, "Error 2 occured in writeKeypairToDatabase1(): $@" );

	}

	return $subresult;

}

sub writeSettingToDatabase1 {

	my ( $key1, $value1 ) = @_;
	my $subresult = 0;

	eval {

		$localDBH->begin_work();

		my $sql1 =
		  "UPDATE TA_SETTINGS SET DS_VALUE=\"$value1\" WHERE DS_KEY=\"$key1\"";

		$localDBH->do($sql1);

		$localDBH->commit();

		$subresult = 1;

		return
		  ; # returns only from this eval block, not from the sub. Very "smart" feature of Perl...

	};

	if ($@) {

		logEvent( 2, "Error 1 occured in writeKeypairToDatabase1(): $@" );

		eval { $localDBH->rollback(); };

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

		my $sth = $localDBH->prepare($sql1);

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

sub appmode2_fetchStatValue_SearchMethod1
{ # stat value is in column left from the stat name, discarding space characters
	my ( $statName, @inputArray ) = @_;
	my $tmpStr1;
	my $returnValue;

	for ( my $i = 0 ; $i < scalar(@inputArray) ; $i++ ) {

		$tmpStr1 = @inputArray[$i];

		if ( $tmpStr1 =~ /\s*(\S*)\s*$statName/ ) {

			$returnValue = $1;
			$i           = scalar(@inputArray);    # quit from the loop

		}

	}

	if ( !defined($returnValue) ) {

		logEvent( 2,
"Error 1 occured in appmode2_fetchStatValue_SearchMethod1(): stat $statName could not be found."
		);

	}

	return $returnValue;

}

#sub appmode2_fetchStatValue_SearchMethod2
#{ # stat value is in column right from the stat name, discarding space characters. stat name starts at the begin of line
#	my ( $statName, @inputArray ) = @_;
#	my $tmpStr1;
#	my $returnValue;
#
#	for ( my $i = 0 ; $i < scalar(@inputArray) ; $i++ ) {
#
#		$tmpStr1 = @inputArray[$i];
#
#		if ( $tmpStr1 =~ /^$statName\s*(\S*)\s*/ ) {
#
#			$returnValue = $1;
#			$i           = scalar(@inputArray);    # quit from the loop
#
#		}
#
#	}
#
#	if ( !defined($returnValue) ) {
#
#		logEvent( 2,
#"Error 1 occured in appmode2_fetchStatValue_SearchMethod2(): stat $statName could not be found."
#		);
#
#	}
#
#	return $returnValue;
#
#}

sub escapeForBashCMDLineParameter {
	my ($line) = @_;

	$line =~ s/\"/\\\"/g    # replace " with \"
	  ;
	return $line;
}

sub appmode2_findLineInArray {
	my ( $line, @inputArray ) = @_;
	my $returnValue = 0;

	for ( my $i = 0 ; $i < scalar(@inputArray) ; $i++ ) {

		if ( @inputArray[$i] eq $line ) {

			$returnValue = 1;
			$i           = scalar(@inputArray);    # quit from the loop

		}

	}

	return $returnValue;

}

sub appmode2_ExtractBlockStatDetail_SearchMethod1 {
	my ( $startLine, @inputArray ) = @_;
	my $copyMode = 0;
	my $tmpStr1;
	my $tmpStr2;
	my @returnArray;
	my $startLinePlusOne;

	#print "b2\n";

	for ( my $i = 0 ; $i < scalar(@inputArray) ; $i++ ) {

		$tmpStr1          = @inputArray[$i];
		$tmpStr2          = @inputArray[ $i + 1 ];
		$startLinePlusOne =
		  "-" x length($startLine)
		  ; # to check underline that follows after the name of block e.g. -----------

		if ( ( $tmpStr1 eq $startLine ) && ( $tmpStr2 eq $startLinePlusOne ) ) {

			#		print "b3\n";
			$copyMode = 1;
		}

		if ( ( $tmpStr1 eq "" ) && ( $copyMode == 1 ) ) {

			#		print "b4\n";
			$copyMode = 2;
			$i        = scalar(@inputArray);    # quit from the loop
		}

		if ( $copyMode == 1 ) {

			#		print "b1\n";
			push( @returnArray, $tmpStr1 );
		}

	}
	return join( "\n", @returnArray );

}

sub appmode2_extractArraySection_SearchType1 {
	my ( $startLineRegex, $endLineRegex ) = @_;
	my $copyMode = 0;
	my $tmpStr1;
	my @returnArray;

	#print "2\n";

	for ( my $i = 0 ; $i < scalar(@appmode2_postfixStatsArray) ; $i++ ) {

		$tmpStr1 = @appmode2_postfixStatsArray[$i];

		if ( $tmpStr1 =~ /$startLineRegex/ ) {

			#print "3\n";
			$copyMode = 1;
		}

		if ( ( $tmpStr1 =~ $endLineRegex ) && ( $copyMode == 1 ) ) {

			#print "4\n";
			$copyMode = 2;
			$i = scalar(@appmode2_postfixStatsArray);    # quit from the loop
		}

		if ( $copyMode == 1 ) {

			#print "1\n";
			push( @returnArray, $tmpStr1 );
		}

	}
	return @returnArray;

}

sub appmode2_loadTextFileToArray1 {
	my ($fileName) = @_;

	@appmode2_postfixStatsArray = ();

	if ( !open( INPUT, $fileName ) ) {

		logEvent( 2, "Error 1 occured in fnLoadTextFileToArray(): $!" );

	}
	else {

		while ( my $line = <INPUT> ) {

			push( @appmode2_postfixStatsArray, $line );
		}

		close(INPUT);

	}

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

		my $sth = $localDBH->prepare($sql1);

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

sub executeShellCommand() {
	my ($cmd1) = @_;
	my $returnSubResult = 0;
	my $execStdErrBackup;
	my $execStdErr;
	my @execOutput;
	my $execResultCode;

	logEvent( 1, "Executing $cmd1" );

	# backup STDERR, to be restored later
	open( $execStdErrBackup, ">&", \*STDERR ) or do {

		logEvent( 2,
			"Error 1 in executeShellCommand(): Can't backup STDERR: $!" );
		$encounteredErrors++;
		return $returnSubResult;
	};

	# close first (according to the perldocs)
	close(STDERR) or return $returnSubResult;

	# redirect STDERR to in-memory scalar

	open( STDERR, '>', \$execStdErr ) or do {
		logEvent( 2,
			"Error 2 in executeShellCommand(): Can't redirect STDERR: $!" );
		$encounteredErrors++;
		return $returnSubResult;
	};

	@execOutput = `$cmd1`;    # execute shell command

	$execResultCode = $? >> 8;

	#$tmpStr1    = @$execStdErr[0];

	# restore original STDERR
	open( STDERR, ">&", $execStdErrBackup ) or do {
		logEvent( 2,
			"Error 3 in executeShellCommand(): Can't restore STDERR: $!" );
		$encounteredErrors++;
		return $returnSubResult;
	};

	logEvent( 1, "Execution result code: $execResultCode" );
	logEvent( 1, "Execution output:" . Dumper(@execOutput) );
	logEvent( 1, "STDERR output: $execStdErr" );

	if ( $execResultCode ne "0" ) {
		logEvent( 2,
"Error 4 in executeShellCommand(): execResultCode is $execResultCode"
		);
		$encounteredErrors++;
		return $returnSubResult;

	}
	else {

		$returnSubResult = 1;

	}

	return ( $returnSubResult, $execResultCode, $execStdErr, \@execOutput );

}
