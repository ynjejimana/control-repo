#!/usr/bin/perl
#### SNMP Monitoring V2 (Zabbix automated SNMP querying utility)
#### Version 1.50
#### Written by: Premysl Botek (premysl.botek@lab.com)
##################################################################################
#### Execution Requirements:
#### * All non-default Perl modules listed as "use" from section "pragmas ..." below (i.e $ yum install perl-Time-HiRes perl-Net-SNMP, $ cpan Config::Std etc.)
##################################################################################
#
#
#

## pragmas, global variable declarations, environment setup

use v5.10;
use strict;
no if $] >= 5.018, 'warnings', "experimental::smartmatch";
use Net::SNMP;
use Data::Dumper;
use Time::Piece;
use Time::Seconds;
use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);
use threads;
use threads::shared;
use DBI;
use DBD::SQLite;
use Net::Telnet ();

# DEPENDENT SETTINGS (values need to be reverified/set correctly during each installation - for this script to work and be integrated with the rest of functionality)

our $scriptsBaseDir = "/srv/zabbix/scripts/snmpmonitoring";
our $logFileName    = "$scriptsBaseDir/log.txt";

my $loggingLevel = 1
  ; # 0 - no logging, 1 - log errors only, 2 - log everything (errors, warnings, debug info)
my $logOutput = 2
  ; # 1 - output to console, 2 - output to log file, 3 - output to both console and log file
my $hostQueryTimeout = 1;    # number of seconds to wait for each SNMP response
my $hostQueryRetries = 2
  ; # number retries if the fist SNMP Get attempt times out ($hostQueryTimeout applies to retries too)

my $zpimZAgentPerf1TracingEnabled = 0;
my $zpimBaseDir                   = "/srv/zabbix/scripts/zpimonitoring";

## End - DEPENDENT SETTINGS

my $thisModuleID =
  "SNMP-GET";    # just for log file record identification purposes

my $zpimDatabase1FileName = "$zpimBaseDir/zpimonitoring.db";
my $zpimZAgentPerf1Tracing_SNMPMonitoringGetDataAnchor1_GUID =
  '7118adaa-95e1-4499-9a7f-789065778fcd';
my $zpimZAgentPerf1Tracing_SNMPMonitoringGetDataAnchor1_TimeStamp0;

my $returnValue;

my $appMode = 0;

my $invalidCommandLine = 0;

my $scriptLogFileErrorsCount;

my $timeoutThreadStatus : shared = 0
  ; # (! must be declared as "shared" - is shared between multiple threads) 0 - unknown, 1 - active waiting to time out, 2 - timed out

## program entry point
## program initialization

my $commandline = join " ", $0, @ARGV;
logEvent( 1, "Used command line: $commandline" );

if ( scalar(@ARGV) < 1 ) {
	$invalidCommandLine = 1;
}
else {

	$invalidCommandLine = 1;

	given ( uc( $ARGV[0] ) ) {

		when ("1") {

			$appMode            = 1;
			$invalidCommandLine = 0;

		}

		when ("2") {

			$appMode            = 2;
			$invalidCommandLine = 0;

		}

		when ("3") {

			$appMode            = 3;
			$invalidCommandLine = 0;

		}

	}

}

if ($invalidCommandLine) {

	my $commandline = join " ", $0, @ARGV;
	logEvent( 2, "Invalid command line: $commandline" );

	print <<USAGELABEL;
Invalid command line parameters
	
USAGE:		perl snmpm-get-data.pl <cmdID> ...
	
* when cmdId is 1, remaining parameters are: <itemOIDprefix> <itemOIDIndex> <Host> <SNMPCommunity> <SNMPVersion> [zabbixHostNameReference] - Executes the specified SNMP query and returns its result. ZabbixHostNameReference is used only for debugging reasons - to identify in the log file where SNMP requests come from. 

* when cmdId is 2 - Returns 'none' or number of errors recorded in the script's .log file (shared by all scripts).

* when cmdId is 3 - Returns 1 or 0 as the result of the SSH service availability test
	
LOGGING:	set \$loggingLevel variable : 0 - no logging, 1 - log errors only, 2 - log everything (errors, warnings, debug info)

		set \$logOutput variable : 1 - output to console, 2 - output to log file, 3 - output to both console and log file
	
USAGELABEL

	exit 0;
}

## main execution block

# add anchor record to the internal monitoring db
zpimZAgentPerf1Entry(
	1,
	$zpimZAgentPerf1Tracing_SNMPMonitoringGetDataAnchor1_GUID,
	\$zpimZAgentPerf1Tracing_SNMPMonitoringGetDataAnchor1_TimeStamp0,
	$$,
	$commandline,
	undef
);

given ($appMode) {

	when (1) {

		my ( $returnCode, $returnValue ) =
		  fnSNMPSingleItemRequest1( $ARGV[1], $ARGV[3], $ARGV[4], $ARGV[6],
			$ARGV[2], $ARGV[5],$ARGV[7] );    # run an SNMP query
		if ( $returnCode == 1 ) {

			print $returnValue

		}

	}

	when (2) {
		$returnValue = fnGetScriptLogFileErrorCount();
		print $returnValue;

	}

	when (3) {
		$returnValue = fnTestSSHAvailability( $ARGV[1] );
		print $returnValue;

	}

}

# remove anchor record from the internal monitoring db
zpimZAgentPerf1Entry(
	2,
	$zpimZAgentPerf1Tracing_SNMPMonitoringGetDataAnchor1_GUID,
	\$zpimZAgentPerf1Tracing_SNMPMonitoringGetDataAnchor1_TimeStamp0,
	$$,
	undef,
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

sub fnTestSSHAvailability {

	my ($machine) = @_;
	my $returnValue = 0;

	my $t = new Net::Telnet(
		Timeout => 5,
		Port    => 22,
		Errmode => "return",
	);

	$t->open($machine);

	#logEvent( 1, "fnTestSSHAvailability() t->errmsg:" . $t->errmsg );

	if ( !( $t->errmsg ) ) {

		if ( $t->waitfor('/SSH/i') ) {

			$returnValue = 1;

		}
	}

	return $returnValue;

}

sub fnSNMPSingleItemRequest1 {
	my ( $itemOIDPrefix, $itemHost, $itemCommunity, $zabbixHostReference,
		$itemOIDSuffix, $SNMPVersion,$SNMPDomain )
	  = @_;
	my $SNMPsession;
	my $SNMPError;
	my $resultCode  = 0;
	my $resultValue = "";
	my $itemOID     = $itemOIDPrefix;

        if (($SNMPDomain eq "")||($SNMPDomain eq "bogus")||($SNMPDomain eq '{}')){
                $SNMPDomain="udp/ipv4";
        }


	if ( $itemOIDSuffix ne "bogus" )
	{ # just to cover the cases when the complete OID is placed in $itemOIDPrefix.$itemOIDSuffix (all except for physical/logical ports on network devices)
		$itemOID .= $itemOIDSuffix;
	}

	( $SNMPsession, $SNMPError ) = Net::SNMP->session(
		-hostname  => $itemHost,
		-version   => $SNMPVersion,
		-translate => [ -all => 0x0 ],
		-community => $itemCommunity,
		-domain => $SNMPDomain,
		-timeout => $hostQueryTimeout,
		-retries => $hostQueryRetries,
	);

	if ( !defined $SNMPsession ) {
		logEvent( 2,
"Error 1 occured in fnSNMPSingleItemRequest1() (zabbixHostReference: $zabbixHostReference) : "
			  . $SNMPError );

		return ( $resultCode, $resultValue );
	}

	logEvent( 1,
"Connecting and requesting $itemOID (zabbixHostReference: $zabbixHostReference)"
	);

	my $result = $SNMPsession->get_request( -varbindlist => [$itemOID], );

	if ( !defined $result ) {

		logEvent( 2,
"Error 2 occured in fnSNMPSingleItemRequest1() (zabbixHostReference: $zabbixHostReference) : "
			  . $SNMPsession->error() );
		$SNMPsession->close();
		return ( $resultCode, $resultValue );
	}

	$resultCode  = 1;
	$resultValue = $result->{$itemOID};

	logEvent( 1,
"SNMP Query successful (zabbixHostReference: $zabbixHostReference) : value of OID $itemOID on host $SNMPsession->hostname() is '$result->{$itemOID}'"
	);

	$SNMPsession->close();

	return ( $resultCode, $resultValue );

}

# will count errors up to $scriptLogFileErrorsCountLimit but not further to not block processing of Zabbix Agent worker for too long in case of very large log files
sub fnGetScriptLogFileErrorCount {    # method Version: 3
	my $returnValue                   = -1;
	my $scriptLogFileErrorsCount      = 0;
	my $scriptLogFileErrorsCountLimit = 1000;

	if ( !open( INPUT, $logFileName ) ) {

		logEvent( 2, "Error 1 occured in fnGetScriptLogFileErrorCount(): $!" );

	}
	else {

		while (( my $line = <INPUT> )
			&& ( $scriptLogFileErrorsCount < $scriptLogFileErrorsCountLimit ) )
		{

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

