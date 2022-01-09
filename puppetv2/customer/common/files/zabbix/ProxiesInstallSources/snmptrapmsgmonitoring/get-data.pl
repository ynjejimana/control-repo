#!/usr/bin/perl
#### Monitoring SNMP Trap Messages (Zabbix automated data retrieval utility)
#### Version 2.32
#### Written by: Premysl Botek (premysl.botek@lab.com)
##################################################################################
#### Execution Requirements:
#### * All non-default Perl modules installed from section "use" below (i.e $ yum install perl-Time-HiRes, $ cpan Config::Std etc.)
##################################################################################
#
#
#

## pragmas, global variable declarations, environment setup

use v5.10;
use strict;
use Config::Simple;
use Data::Dumper;
use DBI;
use Time::Piece;
use Time::Seconds;
use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);
use Net::OpenSSH;

# DEPENDENT SETTINGS (values need to be reverified/set correctly during each installation - for this script to work and be integrated with the rest of functionality)

our $scriptsBaseDir       = "/srv/zabbix/scripts/snmptrapmsgmonitoring";
our $logFileName          = "$scriptsBaseDir/log.txt";
our $coreDatabaseFileName = "$scriptsBaseDir/snmptrapmsgmonitoringdata.db";

our $systemTempDir               = "/tmp";
our $zabbixProxyDatabaseFileName = "$systemTempDir/zabbix_proxy.db";

my $loggingLevel = 2
  ; # 0 - no logging, 1 - log errors only, 2 - log everything (errors, warnings, debug info)
my $logOutput = 2
  ; # 1 - output to console, 2 - output to log file, 3 - output to both console and log file

## End - DEPENDENT SETTINGS


my $webAppURL;
my $webAppScriptFileName = "snmptrappergui.php";



my $thisModuleID =
  "GET-DATA";    # just for log file record identification purposes

my $returnValue;

my $appMode = 0;

my $dbhCoreDatabase;

my $invalidCommandLine = 0;

my $scriptLogFileErrorsCount = 0;

## program entry point
## program initialization

my $commandline = join " ", $0, @ARGV;
logEvent( 1, "Used command line: $commandline" );

if ( scalar(@ARGV) < 1 ) {
	$invalidCommandLine = 1;
}
else {

	logEvent( 1, "t1 " );

	$invalidCommandLine = 1;

	given ( uc( $ARGV[0] ) ) {

		when ("1") {

			$appMode            = 1;
			$invalidCommandLine = 0;

			#logEvent( 1, "t2 " );

		}

		when ("2") {

			$appMode            = 2;
			$invalidCommandLine = 0;

			#logEvent( 1, "t2 " );

		}

		when ("3") {

			$appMode            = 3;
			$invalidCommandLine = 0;

			#logEvent( 1, "t2 " );

		}

	}
}

if ($invalidCommandLine) {

	my $commandline = join " ", $0, @ARGV;
	logEvent( 2, "Invalid command line: $commandline" );

	print <<USAGELABEL;
Invalid command line parameters
	
USAGE:		perl get-data.pl <cmdId>
	

cmdId is 1			Returns 'none' or number of errors recorded in the script's .log file (shared by all scripts).
cmdId is 2			Returns Zabbix Screen - SNMP Trapper V2 Dashboard dynamic html page
cmdId is 3			Returns number of Zabbix_Sender failures today (to be forwarded to an item that fires a trigger)

	
LOGGING:			set \$loggingLevel variable : 0 - no logging, 1 - log errors only, 2 - log everything (errors, warnings, debug info)

				set \$logOutput variable : 1 - output to console, 2 - output to log file, 3 - output to both console and log file


	
USAGELABEL

	exit 0;
}

## main execution block

given ($appMode) {

	when (1) {

		print fnGetScriptLogFileErrors();
	}

	when (2) {

		fnGetHtmlZabbixDashboard();
	}

	when (3) {

		fnGetNumberOfZabbixSenderFailuresToday();

	}

}

## end - main execution block

##  program exit point	###########################################################################

sub fnGetNumberOfZabbixSenderFailuresToday {

	# connect to core database

	if ( !-f $coreDatabaseFileName ) {
		logEvent( 2, "Database file $coreDatabaseFileName does not exist" );
		exit 1;
	}

	$dbhCoreDatabase = DBI->connect(
		"dbi:SQLite:dbname=$coreDatabaseFileName",
		"", "", { RaiseError => 1 },
	  )

	  || { logEvent( 2, "Can't connect to database: $DBI::errstr" )
		  && exit 1 };

	print fnGetTrapMessagesReceivedCount(
"DL_ZABBIX_SENDER_FORWARDING_RESULT_CODE<>1 AND DATE(DT_TIMESTAMP)=date('now','localtime');"
	);

}

sub fnGetHtmlZabbixDashboard {
	my $t0          = gettimeofday() * 1000;
	my $currentDate = localtime->strftime('%Y-%m-%d');

	# connect to core database

	if ( !-f $coreDatabaseFileName ) {
		logEvent( 2, "Database file $coreDatabaseFileName does not exist" );
		exit 1;
	}

	$dbhCoreDatabase = DBI->connect(
		"dbi:SQLite:dbname=$coreDatabaseFileName",
		"", "", { RaiseError => 1 },
	  )

	  || { logEvent( 2, "Can't connect to database: $DBI::errstr" )
		  && exit 1 };

	$webAppURL = readSettingFromDatabase1("WEB_APP_URL");

	if ( !defined($webAppURL) ) {
		logEvent( 2,
			"WEB_APP_URL does not exist in TA_SETTINGS. Terminating." );
		exit 1;
	}

	print "<TABLE border=1 width=100% style='color:white;border-spacing:1px;'>";

	print "<TR><TD style='color:white;'>";

	print "<BR><b>CURRENT SNMP TRAPPER STATUS :</b><BR>";

	# inner table1 - status (today section)
	print
"<TABLE border=1 style='color:white;font-weight:bold;border-spacing:1px;' >";

	print "<TR>";
	print "<TH style='color:white;'>SNMP Trap Messages Received Today</TH>";
	print "<TH style='color:white;'>Unsuccessful Zabbix Submissions Today</TH>";
	print "<TH style='color:white;'>Unrecognized Senders Today</TH>";
	print "<TH style='color:white;'>Unrecognized OIDs Today</TH>";
	print "</TR>";

	print "<TR>";

##

	print
"<TD style='background-color:#FF9999;border-width:1px;text-align:center;'>";

	print "<a style='color:white;font-weight:bold;' href='"
	  . $webAppURL
	  . $webAppScriptFileName
	  . "?a=1&a1trg="
	  . $currentDate
	  . "&a1trs="
	  . $currentDate
	  . "' target='_blank'>"
	  . fnGetTrapMessagesReceivedCount("DATE(DT_TIMESTAMP)=DATE('now');")
	  . "</a>";

	print "</TD>";

##

	print
"<TD style='background-color:#FF9999;border-width:1px;text-align:center;font-weight:bold;'>";

	my $tmpStr1 =
	  fnGetTrapMessagesReceivedCount(
"DL_ZABBIX_SENDER_FORWARDING_RESULT_CODE<>1 AND DATE(DT_TIMESTAMP)=DATE('now');"
	  );

	if ( $tmpStr1 == 0 ) {

		print 0;

	}
	else {

		print "<a style='color:white;font-weight:bold;' href='"
		  . $webAppURL
		  . $webAppScriptFileName
		  . "?a=1&a1zfrc=0&a1trg="
		  . $currentDate
		  . "&a1trs="
		  . $currentDate
		  . "' target='_blank'>"
		  . $tmpStr1 . "</a>";

	}

	print "</TD>";

##

	print
"<TD style='background-color:#FF9999;border-width:1px;text-align:center;font-weight:bold;'>";

	my $tmpStr1 =
	  fnGetTrapMessagesReceivedCount(
		"DL_RECOGNIZED_ZABBIX_HOST<>1 AND DATE(DT_TIMESTAMP)=DATE('now');");

	if ( $tmpStr1 == 0 ) {

		print 0;

	}
	else {

		print "<a style='color:white;font-weight:bold;' href='"
		  . $webAppURL
		  . $webAppScriptFileName
		  . "?a=1&a1ihr=0&a1trg="
		  . $currentDate
		  . "&a1trs="
		  . $currentDate
		  . "' target='_blank'>"
		  . $tmpStr1 . "</a>";

	}

	print "</TD>";

##

	print
"<TD style='background-color:#FF9999;border-width:1px;text-align:center;font-weight:bold;'>";

	my $tmpStr1 =
	  fnGetTrapMessagesReceivedCount(
		"DL_RECOGNIZED_BY_SNMPTT<>1 AND DATE(DT_TIMESTAMP)=DATE('now');");

	if ( $tmpStr1 == 0 ) {

		print 0;

	}
	else {

		print "<a style='color:white;font-weight:bold;' href='"
		  . $webAppURL
		  . $webAppScriptFileName
		  . "?a=1&a1oidr=0&a1trg="
		  . $currentDate
		  . "&a1trs="
		  . $currentDate
		  . "' target='_blank'>"
		  . $tmpStr1 . "</a>";

	}

	print "</TD>";

##

	print "</TR>";

	# END - inner table - status

	#  inner table2 - status (overall section)

	print "<TR>";
	print "<TH style='color:white;'>SNMP Trap Messages Received Overall</TH>";
	print
	  "<TH style='color:white;'>Unsuccessful Zabbix Submissions Overall</TH>";
	print "<TH style='color:white;'>Unrecognized Senders Overall</TH>";
	print "<TH style='color:white;'>Unrecognized OIDs Overall</TH>";
	print "<TH style='color:white;'>Core Script Log Errors Overall</TH>";
	print "</TR>";

	print "<TR>";

##

	print
"<TD style='background-color:#FF9999;border-width:1px;text-align:center;'>";

	print "<a style='color:white;font-weight:bold;' href='"
	  . $webAppURL
	  . $webAppScriptFileName
	  . "?a=8' target='_blank'>"
	  . fnGetTrapMessagesReceivedCount("") . "</a>";

	print "</TD>";

##

	print
"<TD style='background-color:#FF9999;border-width:1px;text-align:center;font-weight:bold;'>";

	my $tmpStr1 =
	  fnGetTrapMessagesReceivedCount(
		"DL_ZABBIX_SENDER_FORWARDING_RESULT_CODE<>1");

	if ( $tmpStr1 == 0 ) {

		print 0;

	}
	else {

		print "<a style='color:white;font-weight:bold;' href='"
		  . $webAppURL
		  . $webAppScriptFileName
		  . "?a=8&a1zfrc=0' target='_blank'>"
		  . $tmpStr1 . "</a>";

	}

	print "</TD>";

##

	print
"<TD style='background-color:#FF9999;border-width:1px;text-align:center;font-weight:bold;'>";

	my $tmpStr1 =
	  fnGetTrapMessagesReceivedCount("DL_RECOGNIZED_ZABBIX_HOST<>1");

	if ( $tmpStr1 == 0 ) {

		print 0;

	}
	else {

		print "<a style='color:white;font-weight:bold;' href='"
		  . $webAppURL
		  . $webAppScriptFileName
		  . "?a=8&a1ihr=0' target='_blank'>"
		  . $tmpStr1 . "</a>";

	}

	print "</TD>";

##

	print
"<TD style='background-color:#FF9999;border-width:1px;text-align:center;font-weight:bold;'>";

	my $tmpStr1 = fnGetTrapMessagesReceivedCount("DL_RECOGNIZED_BY_SNMPTT<>1");

	if ( $tmpStr1 == 0 ) {

		print 0;

	}
	else {

		print "<a style='color:white;font-weight:bold;' href='"
		  . $webAppURL
		  . $webAppScriptFileName
		  . "?a=8&a1oidr=0' target='_blank'>"
		  . $tmpStr1 . "</a>";

	}

	print "</TD>";

##

	print
"<TD style='background-color:#FF9999;color:white;font-weight:bold;border-width:1px;text-align:center;'>";

	my $tmpStr1 = fnGetScriptLogFileErrors();

	if ( $scriptLogFileErrorsCount == 0 ) {

		print 0;

	}
	else {

		print "<a style='color:white;font-weight:bold;' href='"
		  . $webAppURL
		  . $webAppScriptFileName
		  . "?a=2' target='_blank'>$scriptLogFileErrorsCount</a>";

	}

	print "</TD>";

##

	print "</TR>";

	print "</TABLE><BR>";

	# END - inner table - status

##

	my $t1 = gettimeofday() * 1000;

	my ( $s, $usec ) = gettimeofday();    # get microseconds haha
	my $timestamp = localtime->strftime("%Y-%m-%d %H:%M:%S");

	print "<br>This report was completed on $timestamp and took "
	  . sprintf( "%.2f", ( ( $t1 - $t0 ) / 1000 ) )
	  . " seconds to generate<BR><BR>";

##
	print "</TD></TR>";

	print "<TR><TD style='color:white;'>";

	print "<a style='color:#81DAF5;' href='"
	  . $webAppURL
	  . $webAppScriptFileName
	  . "?a=5' target='_blank'>Diagnose Trapper Proxy</a>";

	print "&nbsp;&nbsp;&nbsp;&nbsp;";

	print "<a style='color:#81DAF5;' href='"
	  . $webAppURL
	  . $webAppScriptFileName
	  . "?a=5' target='_blank'>Edit Trapper Proxy Settings</a>";

	print "</TD></TR>";

	print "</TABLE";

}

sub fnGetScriptLogFileErrors {
	my $errorLines;
	my $returnValue;

	$scriptLogFileErrorsCount = 0;

	open( INPUT, $logFileName )

	  || ( $errorLines = "Can not open logfile $logFileName : $!\n" );

	while ( my $line = <INPUT> ) {

		if ( $line =~ / !ERROR! / ) {

			$errorLines = $errorLines . $line . "\n";
			$scriptLogFileErrorsCount++;

		}
	}

	close(INPUT);

	if ( defined($errorLines) ) {
		$returnValue = $errorLines;
	}
	else {

		$returnValue = "_none_";
	}

	logEvent( 1, "Response : $errorLines" );

	return $returnValue;

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


sub readSettingFromDatabase1 {
	my ($key1) = @_;
	my $subresult;

	eval {

		my $sql1 = "SELECT DS_VALUE FROM TA_SETTINGS WHERE DS_KEY=?";

		my $sth = $dbhCoreDatabase->prepare($sql1);

		$sth->execute($key1);

		($subresult) = $sth->fetchrow_array();

		$sth->finish();   # end statement, release resources (not a transaction)

		if ( !defined($subresult) ) {

			logEvent( 2, "The setting value for the key $key1 does not exist" );

		}

	};

	if ($@) {

		logEvent( 2, "Error 1 occured in readSettingFromDatabase1(): $@" );

	}

	return $subresult;

}

sub fnGetTrapMessagesReceivedCount {
	my ($queryModifierWhere) = @_;
	my $resultValue;

	eval {

		my $sql1 = "SELECT COUNT(1) FROM TA_RECEIVED_TRAP_MSGS";

		if ( $queryModifierWhere ne "" ) {
			$sql1 = $sql1 . " WHERE " . $queryModifierWhere;
		}

		my $sth = $dbhCoreDatabase->prepare($sql1);

		$sth->execute();

		($resultValue) = $sth->fetchrow_array();

		$sth->finish();   # end statement, release resources (not a transaction)

	};

	if ($@) {

		logEvent( 2,
			"Error 1 occured in fnGetTrapMessagesReceivedCount(): $@" );

	}

	return $resultValue;

}
