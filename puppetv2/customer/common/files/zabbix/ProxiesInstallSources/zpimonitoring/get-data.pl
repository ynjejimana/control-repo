#!/usr/bin/perl
#### Zabbix Proxy Internal Monitoring (Zabbix data forwarding)
#### Version 1.9
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
use Data::Dumper;
use Time::Piece;
use Time::Seconds;
use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);
use DBI;
use DBD::SQLite;

# DEPENDENT SETTINGS (values need to be reverified/set correctly during each installation - for this script to work and be integrated with the rest of functionality)

our $zpimBaseDir = "/srv/zabbix/scripts/zpimonitoring";

my $zpimZAgentPerf1TracingEnabled = 1;



my $loggingLevel = 2
  ; # 0 - no logging, 1 - log errors only, 2 - log everything (errors, warnings, debug info)
my $logOutput = 3
  ; # 1 - output to console, 2 - output to log file, 3 - output to both console and log file

## End - DEPENDENT SETTINGS

our $logFileName           = "$zpimBaseDir/log.txt";
our $zpimDatabase1FileName = "$zpimBaseDir/zpimonitoring.db";

my $thisModuleID =
  "GET-DATA";    # just for log file record identification purposes

my $returnValue;

my $appMode = 0;

my $invalidCommandLine = 0;

my $scriptLogFileErrorsCount;

my $currentZabbixHostReference;

my $dbh;

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

	}

}

if ($invalidCommandLine) {

	my $commandline = join " ", $0, @ARGV;
	logEvent( 2, "Invalid command line: $commandline" );

	print <<USAGELABEL;
Invalid command line parameters
	
USAGE:		perl snmp-get.pl <cmdID> ...
	
* when cmdId is 1, remaining parameters are: <itemOIDprefix> <itemOIDsuffix> <queriedHost> <itemCommunity> <SNMPVersion> zabbixHostNameReference> - Returns result of the SNMP query. ZabbixHostNameReference is used only for debugging reasons - to identify where invalid OID requests come from. 

* when cmdId is 2 - Returns 'none' or number of errors recorded in the script's .log file (shared by all scripts).
	
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
#		fnDumpAll1();

	}

}

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



sub readSettingFromDatabase1 {
	my ( $key1, $value1 )
	  =    # expects reference to variable $value1 (so it can modify it)
	  @_;
	my $tmp1;
	my $tmp2;
	my $subresult = 0;

	#my $DBI;

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
