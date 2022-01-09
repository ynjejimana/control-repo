#!/usr/bin/perl
#### Monitoring Commvault Backup Logs
#### Version 2.1
#### Writen by: Premysl Botek (pbotek@harbourmsp.com)
##################################################################################

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

our $basedir              = "/srv/zabbix/scripts/clmonitoring";
our $datadir              = "/clmdata";
our $slowDatabaseFileName = "$datadir/database/clmonitoringdata_slow.db";
our $fastDatabaseFileName = "$datadir/database/clmonitoringdata_fast.db";
our $logFileName          = "$datadir/scriptslog/log.txt";

my $loggingLevel = 1
  ; # 0 - no logging, 1 - log errors only, 2 - log everything (errors, warnings, debug info)
my $logOutput = 2
  ; # 1 - output to console, 2 - output to log file, 3 - output to both console and log file

my $thisModuleID =
  "GET-DATA";    # just for log file record identification purposes

my $returnValue;

my $selectedDate1;
my $selectedDate1Offset;
my $selectedDate2;
my $selectedDate2Offset;

my $rdcefpSelectedDate1;
my $rdcefpSelectedDate1Offset;
my $rdcefpSelectedDate2;
my $rdcefpSelectedDate2Offset;

my $rdcefcSelectedDate1;
my $rdcefcSelectedDate1Offset;
my $rdcefcSelectedDate2;
my $rdcefcSelectedDate2Offset;

my $consecutiveDaysNumber;

# 2 - metadata-SCRIPTSLOGFILEERRORS
# 4 - metadata-IMPORTPROCEDURELOCK
# 8 - metadata databasecachingstatus
# 9 - metadata dropboxpickup
my $appMode = 0;
my $slowDBH;

#my $fastDBH;
my $invalidCommandLine = 0;
my $ssh_pipe;
my $failedShellCommandsCount = 0;
my @collectedDetails_cmdFincore;
my $executionResult_cmdFincore;
my @collectedDetails_cmdFree;
my $executionResult_cmdFree;
my $databaseSize;
my $databaseCachedSize;
my $databaseCachedPercentage;
my $memoryAvailableForCache;
my $displayOverallInfo;
my $displayClientErrorInfo;
my $displayXConsecutiveClientErrorInfo;
my $currentDropboxId;
my $dashboardGenerationProcedureLock;

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

		when ("METADATA") {

			if ( uc( $ARGV[1] ) eq "SCRIPTSLOGFILEERRORS" ) {

				$appMode            = 2;
				$invalidCommandLine = 0;

			}

			if ( uc( $ARGV[1] ) eq "DROPBOXPICKUP" ) {

				$currentDropboxId = $ARGV[2];

				if ( defined($currentDropboxId) ) {

					$appMode            = 9;
					$invalidCommandLine = 0;

				}
			}

		}

	}
}

if ($invalidCommandLine) {

	my $commandline = join " ", $0, @ARGV;
	logEvent( 2, "Invalid command line: $commandline" );

	print <<USAGELABEL;
Invalid command line parameters
	
USAGE:		perl get-data.pl <METADATA>
	

METADATA DROPBOXPICKUP <dropboxId>		- Returns the value stored in dropbox (TA_DROPBOX of clmonitoringdata_fast.db) under the specified dropboxId

METADATA SCRIPTSLOGFILEERRORS		- Returns number of errors recorded in the script's .log file (shared by all scripts).


	
LOGGING:	set \$loggingLevel variable : 0 - no logging, 1 - log errors only, 2 - log everything (errors, warnings, debug info)

		set \$logOutput variable : 1 - output to console, 2 - output to log file, 3 - output to both console and log file

NOTE:		do not use characters " _ ' in the command line
	
USAGELABEL

	exit 0;
}

## main execution block

given ($appMode) {

	when (2) {

		print fnGetScriptLogFileErrorCount();
	}

	when (9) {

		my $returnValue = getDropboxData($currentDropboxId);
		my $schedulerStatus;

		readSettingFromDatabase1( "SCHEDULER_STATUS", \$schedulerStatus )
		  or exit 1;

		if ( !defined($schedulerStatus) ) {
			logEvent( 2, "SCHEDULER_STATUS does not exist in TA_SETTINGS" );
			exit 1;

		}

		$schedulerStatus = "Scheduler status: $schedulerStatus</br>";

# inject currrent scheduler status read from fast database into the returned string (if XXXSCHEDULER_STATUS_PLACEHOLDERXXX exists in it, i.e. is produced by DASHBOARD generation procedure)
		$returnValue =~ s/XXXSCHEDULER_STATUS_PLACEHOLDERXXX/$schedulerStatus/g;

		print $returnValue;
		logEvent( 1, "Response : $returnValue" );

	}

}

## end - main execution block

##  program exit point	###########################################################################

sub getDropboxData {
	my ($key1) = @_;

	my $returnValue;

	eval {

		# connect to database

		if ( !-f $slowDatabaseFileName ) {
			logEvent( 2, "Database file $slowDatabaseFileName does not exist" );
			exit 1;
		}

		$slowDBH = DBI->connect(
			"dbi:SQLite:dbname=$slowDatabaseFileName",
			"", "", { RaiseError => 1 },
		);

		readValueFromDropbox1( $key1, \$returnValue )
		  or exit 1;

		if ( !defined($returnValue) ) {
			logEvent( 2, "$key1 does not exist in TA_DROPBOX" );
			exit 1;

		}

		$slowDBH->disconnect();

	};

	if ($@) {
		logEvent( 2, "Error 1 in getDropboxData(): $@" );
		exit 1;
	}

	return $returnValue;

}




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
	my $fastDBHTmp;

	if ( !-f $fastDatabaseFileName ) {
		logEvent( 2, "Database file $fastDatabaseFileName does not exist" );
		exit 1;
	}

	eval {

		my $fastDBHTmp = DBI->connect(
			"dbi:SQLite:dbname=$fastDatabaseFileName",
			"", "", { RaiseError => 1 },
		);

		my $sql1 = "SELECT DS_VALUE FROM TA_SETTINGS WHERE DS_KEY=\"$key1\"";

		my $sth = $fastDBHTmp->prepare($sql1);

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

		$fastDBHTmp->disconnect();

		$subresult = 1;

		return
		  ; # returns only from this eval block, not from the sub. Very "smart" feature of Perl...

	};

	if ($@) {

		logEvent( 2, "Error 1 occured in readSettingFromDatabase1(): $@" );

	}

	return $subresult;

}

sub readValueFromDropbox1 {
	my ( $key1, $value1 )
	  =    # expects reference to variable $value1 (so it can modify it)
	  @_;
	my $tmp1;
	my $tmp2;
	my $subresult = 0;
	my $fastDBHTmp;

	if ( !-f $fastDatabaseFileName ) {
		logEvent( 2, "Database file $fastDatabaseFileName does not exist" );
		exit 1;
	}

	eval {

		my $fastDBHTmp = DBI->connect(
			"dbi:SQLite:dbname=$fastDatabaseFileName",
			"", "", { RaiseError => 1 },
		);

		my $sql1 = "SELECT DS_VALUE FROM TA_DROPBOX WHERE DS_KEY=\"$key1\"";

		my $sth = $fastDBHTmp->prepare($sql1);

		$sth->execute();

		$tmp1 = $sth->fetch();

		$sth->finish();   # end statement, release resources (not a transaction)

		if ( !defined($tmp1) ) {

			logEvent( 2, "The dropbox key $key1 does not exist" );
			return
			  ; # returns only from this eval block, not from the sub. Very "smart" feature of Perl...
		}

		$$value1 =
		  @$tmp1[0]
		  ; # dereference array referenced by $tmp1, retrieve its first item and store it in a scalar variable that is referenced by $value1

		$fastDBHTmp->disconnect();

		$subresult = 1;

		return
		  ; # returns only from this eval block, not from the sub. Very "smart" feature of Perl...

	};

	if ($@) {

		logEvent( 2, "Error 1 occured in readValueFromDropbox1(): $@" );

	}

	return $subresult;

}

