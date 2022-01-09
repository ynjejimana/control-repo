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
#use Net::OpenSSH;

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
  "SCHEDULER";    # just for log file record identification purposes

my $currentJobOrderNumber;
my $currentJobId;
my $currentJobCommandLine;
my $ssh_pipe;
my $lastScheduledJobRetrievalResult = 1;
my @collectedDetails_ShellCmd;

#my $executionResult_ShellCmd;
my $failedShellCommandsCount;
my $schedulerLock;

## program entry point
## program initialization

## prevent multiple instances to run

readSettingFromDatabase1( "SCHEDULER_LOCK", \$schedulerLock )
  or exit 1;

if ( !defined($schedulerLock) ) {
	logEvent( 2, "SCHEDULER_LOCK does not exist in TA_SETTINGS" );
	exit 1;

}

if ( uc($schedulerLock) ne "NIL" ) {

	logEvent( 1,
"Can't proceed at this time, previous scheduler procedure has not completed yet. SCHEDULER_LOCK="
		  . $schedulerLock );
	exit 1;
}

## run scheduler

logEvent( 1, "Running scheduler" );

my $timeStamp = localtime->strftime("%Y-%m-%d %H:%M:%S");
writeSettingToDatabase1( "SCHEDULER_LOCK", $timeStamp ) or exit 1;

$currentJobOrderNumber = 0;

while ($lastScheduledJobRetrievalResult) {

	$lastScheduledJobRetrievalResult = getNextScheduledJobDetails1();

	if ($lastScheduledJobRetrievalResult) {

		my $timeStamp       = localtime->strftime("%Y-%m-%d %H:%M:%S");
		my $schedulerStatus =
		  "since $timeStamp running sjobId $currentJobId ("
		  . $currentJobCommandLine . ")";

		writeSettingToDatabase1( "SCHEDULER_STATUS", $schedulerStatus )
		  or exit 1;

		#executeScheduledJob1();

		#my $scalar = join( '', @collectedDetails_ShellCmd );

		#UpdateScheduledJobDetails1( $currentJobId, $scalar );

		my $tmp1 = executeShellCommand("$basedir/$currentJobCommandLine");

		if ( $tmp1 != 1 ) {
			$failedShellCommandsCount++;
		}

		UpdateScheduledJobDetails1( $currentJobId, $tmp1 );

	}

}

writeSettingToDatabase1( "SCHEDULER_STATUS", "sleeping" ) or exit 1;

writeSettingToDatabase1( "SCHEDULER_LOCK", "nil" ) or exit 1;

logEvent( 1, "Finished scheduler run" );

## end - main execution block

##  program exit point	###########################################################################

sub UpdateScheduledJobDetails1 {
	my ( $jobId, $lastResult ) = @_;
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

		my $sql1 =
"UPDATE TA_SCHEDULER SET DT_LAST_COMPLETED=datetime( 'now', 'localtime' ), DS_LAST_RESULT=? WHERE DL_ID=?";

#		logEvent( 1,
#"UpdateScheduledJobDetails1 Sql1: UPDATE TA_SCHEDULER SET DT_LAST_COMPLETED=datetime( 'now', 'localtime' ), DS_LAST_RESULT='"
#			  . $lastResult
#			  . "' WHERE DL_ID=$jobId" );

		my $sth = $fastDBHTmp->prepare($sql1);

		my $rows_affected = $sth->execute( $lastResult, $jobId );

		$sth->finish();   # end statement, release resources (not a transaction)

		if ( $rows_affected == 1 ) {

			$subresult = 1;

		}
		else {

			logEvent( 2,
"Error 1 occured in UpdateScheduledJobDetails1(): Jobid $jobId does not exist in TA_SCHEDULER."
			);

		}

		$fastDBHTmp->disconnect();

		return
		  ; # returns only from this eval block, not from the sub. Very "smart" feature of Perl...

	};

	if ($@) {

		logEvent( 2, "Error 2 occured in UpdateScheduledJobDetails1(): $@" );

	}

	return $subresult;

}

#sub executeScheduledJob1 {
#	my $result1;
#
#	$ssh_pipe = Net::OpenSSH->new(
#		"127.0.0.1",
#
#		#		"172.17.12.179",
#		master_opts => [
#			-o => "StrictHostKeyChecking=no",
#			-o => "ConnectTimeout 30"
#		],
#
#		user     => "root",
#		password =>
#		  "5acred1y",  # use this if you do not want passwordless authentication
#		strict_mode => 0,
#
#	);
#
#	$ssh_pipe->error
#	  &&{ logEvent( 2, "SSH connection failed1: " . $ssh_pipe->error )
#		  && exit 1 };
#
### run Shell
#
#	#	if (
#	#		runShell(
#	#			"$basedir/$currentJobCommandLine",
#	#			\@collectedDetails_ShellCmd
#	#		)
#	#	  )
#	#	{
#	#
#	#		$executionResult_ShellCmd = 0;
#	#
#	#	}
#	#	else {
#	#		$executionResult_ShellCmd = 1;
#	#		$failedShellCommandsCount++;
#	#	}
#
#}

sub getNextScheduledJobDetails1 {

	my $tmp1;
	my $tmp2;
	my $subresult = 0;
	my $fastDBHTmp;
	my @rowArray1;

	if ( !-f $fastDatabaseFileName ) {
		logEvent( 2, "Database file $fastDatabaseFileName does not exist" );
		exit 1;
	}

	eval {

		my $fastDBHTmp = DBI->connect(
			"dbi:SQLite:dbname=$fastDatabaseFileName",
			"", "", { RaiseError => 1 },
		);

		my $sql1 = <<DELIMITER1;

SELECT DL_ID,
       DS_COMMAND_LINE,
       DL_ORDER_NUMBER
  FROM TA_SCHEDULER
 WHERE DL_ORDER_NUMBER > ? 
       AND
       DATETIME( DATETIME( DT_LAST_COMPLETED ) , '+'||DL_RUN_INTERVAL||' second' )  < DATETIME( 'now', 'localtime' );

DELIMITER1

		my $sth = $fastDBHTmp->prepare($sql1);

		$sth->execute($currentJobOrderNumber);

		( $currentJobId, $currentJobCommandLine, $currentJobOrderNumber ) =
		  $sth->fetchrow_array();

		$sth->finish();   # end statement, release resources (not a transaction)

		if ( !defined($currentJobId) ) {

			logEvent( 1, "Did not find any jobs to run" );
			return
			  ; # returns only from this eval block, not from the sub. Very "smart" feature of Perl...
		}
		else {

			logEvent( 1,
"Found new job to execute: currentJobOrderNumber=$currentJobOrderNumber , JobId=$currentJobId , currentJobCommandLine=$currentJobCommandLine"
			);

			$subresult = 1;

		}

		$fastDBHTmp->disconnect();

		return
		  ; # returns only from this eval block, not from the sub. Very "smart" feature of Perl...

	};

	if ($@) {

		logEvent( 2, "Error 1 occured in readSettingFromDatabase1(): $@" );

	}

	return $subresult;

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

sub executeShellCommand() {
	my ($cmd1) = @_;
	my $resultValue = 0;
	my $stdErrBackup;
	my $stdErr;
	my @execOutput;
	my $execResultCode;

	logEvent( 1, "Executing $cmd1" );

	# backup STDERR, to be restored later
	open( $stdErrBackup, ">&", \*STDERR ) or do {

		logEvent( 2,
			"Error 1 in executeShellCommand(): Can't backup STDERR: $!" );
		return $resultValue;
	};

	# close first (according to the perldocs)
	close(STDERR) or return $resultValue;

	# redirect STDERR to in-memory scalar

	open( STDERR, '>', \$stdErr ) or do {
		logEvent( 2,
			"Error 2 in executeShellCommand(): Can't redirect STDERR: $!" );
		return $resultValue;
	};

	@execOutput = `$cmd1`;    # execute shell command

	$execResultCode = $? >> 8;

	#$tmpStr1    = @$stdErr[0];

	# restore original STDERR
	open( STDERR, ">&", $stdErrBackup ) or do {
		logEvent( 2,
			"Error 3 in executeShellCommand(): Can't restore STDERR: $!" );
		return $resultValue;
	};

	#logEvent( 1, "Execution result code: $execResultCode" );
	#logEvent( 1, "Execution output:".Dumper(@execOutput) );
	#logEvent( 1, "STDERR output: $stdErr" );

	if ( $execResultCode eq "0" ) {
		$resultValue = 1;
	}
	else {

		logEvent( 2,
"Error 4 in executeShellCommand(): Execution result code is $execResultCode"
		);

	}

	return $resultValue;

}

#
#sub runShell {
#	my ( $cmd, $collectedDetails_ref ) =
#	  @_;    # expects reference to $collectedDetails
#
#	logEvent( 1, "Executing Shell command : $cmd" );
#
#	my ( $sshReadBuffer, $errput ) =
#	  $ssh_pipe->capture2( { timeout => 3600, stdin_discard => 1 }, $cmd )
#	  ; # doco says that capture function honours input separator settings (local $/ = "\n";) when in array context, but really it does not...
#
##	!Don't use statement " || { logEvent( 2, "Error 1 occured in query_hypervisor() : " . $ssh_pipe->error )
##		  && return 0 }; " in here or $errput will not be retrieved correctly...
#
#	if ( $ssh_pipe->error ) {
#		#if (( $ssh_pipe->error )&&(!($ssh_pipe->error =~ /child exited with code 1/))) {
#
#
#
#		logEvent( 2,
#			"Error 1 occured in runShell(), Net::SSH error : "
#			  . $ssh_pipe->error );
#		return 0;
#
#	}
#
#	if ( !( $errput eq "" )
#		&& ( !( $errput =~ /^Killed by signal.*/ ) )
#	  )    # make exception for 'Killed by signal x'
#
#	{
#		$errput =~ s/\n//g;
#		logEvent( 2,
#			    "Error 2 in runShell(). Encountered error \"" . $errput
#			  . "\" in remote command \"$cmd\"" );
#		return 0;
#	}
#
#	@$collectedDetails_ref = split "\n",
#	  $sshReadBuffer;    # modifies referred array, wot a beauti
#	foreach my $item (@$collectedDetails_ref) {
#
#		$item = $item . "\n";
#	}
#
#	logEvent( 1, "Shell command result: " . Dumper(@$collectedDetails_ref) );
#
#	return 1;
#
#}

sub writeSettingToDatabase1 {
	my ( $key1, $value1 ) = @_;
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

		my $sql1 = "UPDATE TA_SETTINGS SET DS_VALUE=? WHERE DS_KEY=?";

		my $sth = $fastDBHTmp->prepare($sql1);

		my $rows_affected = $sth->execute( $value1, $key1 );

		$sth->finish();   # end statement, release resources (not a transaction)

		if ( $rows_affected == 1 ) {

			$subresult = 1;

		}
		else {

			logEvent( 2,
"Error 1 occured in writeKeypairToDatabase1(): Setting '$key1' does not exist."
			);

		}

		$fastDBHTmp->disconnect();

		return
		  ; # returns only from this eval block, not from the sub. Very "smart" feature of Perl...

	};

	if ($@) {

		logEvent( 2, "Error 2 occured in writeSettingToDatabase1(): $@" );

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
