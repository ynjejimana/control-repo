#!/usr/bin/perl
#### Zabbix Item Retrieval Latency Benchmark
#### Version 1.2
#### Writen by: Premysl Botek (premysl.botek@lab.com)
#### Requires additinal Perl modules installed: Config::Simple, Time::HiRes, Time::Piece, DBI, DBD::SQLite
#### If some PERL modules cant be installed via CPAN: Yum install perl-DBD-mysql, perl-DBI
##################################################################################

## pragmas, global variable declarations, environment setup

use v5.10;
use strict;
use Config::Simple;
use Data::Dumper;
use Time::Piece;
use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);
use DBI;
use File::Path;
use Time::HiRes qw(gettimeofday);
use Time::Local;

my $dbname   = "zabbix";
my $host     = "172.17.7.105";
my $dsn      = "dbi:mysql:database=$dbname;host=$host";
my $user     = "zabbix";
my $password = "zabbix";

our $localDatabaseFileName = "benchmarkdata.db";

our $logfilename = "log.txt";
my $remoteMySqlDBH;
my $localSQLiteDBH;

my $loggingLevel = 2
  ; # 0 - no logging, 1 - log errors only, 2 - log everything (errors, warnings, debug info)
my $logOutput = 3
  ; # 1 - output to console, 2 - output to log file, 3 - output to both console and log file

my $thisModuleID = "APP";    # just for log file record identification purposes

my $invalidCommandLine = 0;

my $appMode = 0;	# CHECK1 - check items on specified host, CHECK2 - check items on all hosts on specified proxy 

my $totalDayTimeConsumption=0;

my $currentProxyName;
my $currentHostName;
my $currentTemplateName;
my $currentProxyId;
my $currentHostId;
my $currentTemplateId;
my $generalErrorCounter  = 0;
my $purgeHistoryTextData = 0;

my $confirmRemoteMySqlCommit = 0;

## program entry point 	###########################################################################

# configure program mode, depending on command-line parameters

$invalidCommandLine = 1;

if (   ( uc( $ARGV[0] ) eq "CHECK1" )
	&& ( defined( $ARGV[1] ) ) )
{
	$appMode            = 1;
	$currentHostName    = $ARGV[1];
	$invalidCommandLine = 0;

}



if (   ( uc( $ARGV[0] ) eq "CHECK2" )
	&& ( defined( $ARGV[1] ) ) )
{
	$appMode            = 2;
	$currentProxyName    = $ARGV[1];
	$invalidCommandLine = 0;

}

if ($invalidCommandLine) {

	print <<USAGELABEL;
Invalid command line parameters

Usage: ZabbixItemRetrievalLatencyBenchmark.pl <CHECK1|CHECK2> <hostname|proxyname> 

	
CHECK1 <hostname> - checks items on specified host
CHECK2 <proxyname> - check items on all hosts on specified proxy

	
USAGELABEL

	exit 0;
}

## main execution block

eval {

	given ($appMode) {

		when (1) {

			fnBenchmark1();

		}
		
		
		
		when (2) {

			fnBenchmark2();

		}

	}

};

if ($@) {

	logEvent( 2, "Error 1 occured in main(): $@" );

}

if ( $generalErrorCounter == 0 ) {
	logEvent( 1, "Successfuly completed. TotalDayTimeConsumption = ".($totalDayTimeConsumption/1000)." sec, equal to ".($totalDayTimeConsumption/(60*60*24*1000))." of clean Agent listener/worker thread time" );
}
else {
	logEvent( 1, "Completed with $generalErrorCounter errors." );
}

## end - main execution block

##  program exit point	###########################################################################

## service functions

## use stdin for user input, generic function
sub askQuestionYN {
	my ( $question, $defaultResponse ) = @_;
	my $response;
	my $result1 = 0;

	if ($defaultResponse) {

		print "$question [Y/n] ";

		chomp( $response = <STDIN> );

		if ( uc($response) ne "N" ) {
			$result1 = 1;
		}

	}
	else {

		print "$question [y/N] ";

		chomp( $response = <STDIN> );

		if ( uc($response) eq "Y" ) {
			$result1 = 1;
		}

	}

	return $result1;

}

sub logEvent {
	my ( $eventType, $msg ) =
	  @_;    # event type: 1 - debug info, 2 - error, 3 - warning

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

		print "$timestamp$eventTypeDisplay$msg\n";

	}

	if ( ( $logOutput == 2 ) || ( $logOutput == 3 ) ) {

		open( LOGFILEHANDLE, ">>$logfilename" )
		  || ( print "Can not open logfile $logfilename : $!\n" && exit 1 );
		print LOGFILEHANDLE "[$thisModuleID] $timestamp$eventTypeDisplay$msg\n";
		close LOGFILEHANDLE;

	}

}

sub findHostIdByName {
	my ($hostName) = @_;
	my $returnValue;

	eval {

		my $sql1 = <<DELIMITER1;

SELECT hostid 
FROM hosts WHERE 
host=? 
AND status=0
 		
DELIMITER1

		my $sth1 = $remoteMySqlDBH->prepare($sql1);

		$sth1->execute($hostName);

		$returnValue = $sth1->fetchrow_array();

		$sth1->finish();

		if ( !defined($returnValue) ) {

			logEvent( 2,
"Error 1 occured in findHostIdByName(): Can not find host '$hostName'"
			);

			$generalErrorCounter++;

		}
		else {

			logEvent( 1, "Found host '$hostName', id $returnValue " );

		}

	};

	if ($@) {

		logEvent( 2, " Error 2 occured in findHostIdByName() : $@ " );
		$generalErrorCounter++;

	}

	return $returnValue;

}




sub findProxyIdByName {
	my ($proxyName) = @_;
	my $returnValue;

	eval {

		my $sql1 = <<DELIMITER1;

SELECT hostid 
FROM hosts WHERE 
host=? 
AND status=5
 		
DELIMITER1

		my $sth1 = $remoteMySqlDBH->prepare($sql1);

		$sth1->execute($proxyName);

		$returnValue = $sth1->fetchrow_array();

		$sth1->finish();

		if ( !defined($returnValue) ) {

			logEvent( 2,
"Error 1 occured in findProxyIdByName(): Can not find host '$proxyName'"
			);

			$generalErrorCounter++;

		}
		else {

			logEvent( 1, "Found proxy '$proxyName', id $returnValue " );

		}

	};

	if ($@) {

		logEvent( 2, " Error 2 occured in findHostIdByName() : $@ " );
		$generalErrorCounter++;

	}

	return $returnValue;

}

## creates local Sqlite database to store backed up Zabbix history in
sub fnCreateNewLocalDatabase {

	eval {

		$localSQLiteDBH = DBI->connect(
			"dbi:SQLite:dbname=$localDatabaseFileName",
			"", "",
			{ RaiseError => 1, sqlite_allow_multiple_statements => 1, }
			, # important to be able to run multiple statements within one Do() run
		);

		my $ss1 = getLocalDatabaseCreationStatement();
		$localSQLiteDBH->do($ss1);

		$localSQLiteDBH->disconnect();

		logEvent( 1, "Successfully created $localDatabaseFileName" );

	};
	if ($@) {
		logEvent( 2, "Database error ($localDatabaseFileName): $@" );
		exit 1;
	}

}





sub fnBenchmark2 {

	# first create a new clean Sqlite database
	eval {

		if ( -f $localDatabaseFileName ) {

			if (
				askQuestionYN(
"File $localDatabaseFileName already exists. Do you want to delete it now?",
					1
				) == 1
			  )
			{
				logEvent( 1, "Deleting $localDatabaseFileName" );
				unlink($localDatabaseFileName);

			}
			else {

				logEvent( 1, "User abort" );
				exit 1;

			}

		}

		logEvent( 1, "Connecting to $dsn" );

		$remoteMySqlDBH =
		  DBI->connect( $dsn, $user, $password, { RaiseError => 1 } );

		logEvent( 1, "Connected" );
		$remoteMySqlDBH->{PrintError} = 0;

## find ids of requested objects

		$currentProxyId = findProxyIdByName($currentProxyName);	

		fnCreateNewLocalDatabase();

		$localSQLiteDBH = DBI->connect(
			"dbi:SQLite:dbname=$localDatabaseFileName",
			"", "",
			{
				RaiseError                       => 1,
				sqlite_allow_multiple_statements => 1,
			}, # important to be able to run multiple statements within one Do() run
		);





		my $sql1 = <<DELIMITER1;

SELECT hostid,host 
FROM hosts WHERE 
proxy_hostid=? 

 		
DELIMITER1

		my $sth1 = $remoteMySqlDBH->prepare($sql1);

		$sth1->execute($currentProxyId);


		my @rowArray1;

		while ( @rowArray1 = $sth1->fetchrow_array() ) {		# loop through hosts for selected proxy
	


		fnGenerateItemList( @rowArray1[1], @rowArray1[0] );


		}


		$remoteMySqlDBH->disconnect();
		logEvent( 1, "Disconnected from $dsn" );

		fnRunCheck1();

		$localSQLiteDBH->disconnect();

	};
	if ($@) {
		logEvent( 2, "Error 1 in fnBenchmark2(): $@" );
		$generalErrorCounter++;
	}

}


sub fnBenchmark1 {

	# first create a new clean Sqlite database
	eval {

		if ( -f $localDatabaseFileName ) {

			if (
				askQuestionYN(
"File $localDatabaseFileName already exists. Do you want to delete it now?",
					1
				) == 1
			  )
			{
				logEvent( 1, "Deleting $localDatabaseFileName" );
				unlink($localDatabaseFileName);

			}
			else {

				logEvent( 1, "User abort" );
				exit 1;

			}

		}

		logEvent( 1, "Connecting to $dsn" );

		$remoteMySqlDBH =
		  DBI->connect( $dsn, $user, $password, { RaiseError => 1 } );

		logEvent( 1, "Connected" );
		$remoteMySqlDBH->{PrintError} = 0;

## find ids of requested objects

		$currentHostId = findHostIdByName($currentHostName);

		fnCreateNewLocalDatabase();

		$localSQLiteDBH = DBI->connect(
			"dbi:SQLite:dbname=$localDatabaseFileName",
			"", "",
			{
				RaiseError                       => 1,
				sqlite_allow_multiple_statements => 1,
			}, # important to be able to run multiple statements within one Do() run
		);

		fnGenerateItemList( $currentHostName, $currentHostId );

		$remoteMySqlDBH->disconnect();
		logEvent( 1, "Disconnected from $dsn" );

		fnRunCheck1();

		$localSQLiteDBH->disconnect();

	};
	if ($@) {
		logEvent( 2, "Error 1 in fnExportHostTemplateHistory(): $@" );
		$generalErrorCounter++;
	}

}

sub fnRunCheck1 {

	my $cmd1;
	my $returnValue   = 1;
	my $valuesCounter = 0;

	eval {

		my $sql1 = <<DELIMITER1;

SELECT DL_ID,DS_ITEMKEY,DL_ZDELAY FROM TA_LOG;
 		
DELIMITER1

		my $sth1 = $localSQLiteDBH->prepare($sql1);

		$sth1->execute();

		my @rowArray1;

		while ( @rowArray1 = $sth1->fetchrow_array() ) {

			$valuesCounter++;

			$cmd1 = "zabbix_get -s$ARGV[1] -p10050 -k\"@rowArray1[1]\" 2>&1";

			my $t0 = int( gettimeofday() * 1000 );

			my @output = `$cmd1`;    # execute shell command

			my $t1      = int( gettimeofday() * 1000 );
			my $latency = $t1 - $t0;

			my $output1=@output[0];
			chomp($output1);
			
			my $dayTimeConsumption=int((60*60*24)/@rowArray1[2]*$latency);
			$totalDayTimeConsumption=$totalDayTimeConsumption+$dayTimeConsumption;

			logEvent( 1, "id: @rowArray1[0], latency: $latency, daytimeconsumption: $dayTimeConsumption, ($cmd1) ($output1)\n" );

			my $sql2 = <<DELIMITER2;

UPDATE TA_LOG SET DL_CHECKLATENCY=?,DS_CHECKOUTPUT=?,DL_DAYTIMECONSUMPTION=?
WHERE DL_ID=?
 		
DELIMITER2

			my $sth2 = $localSQLiteDBH->prepare($sql2);
			$sth2->execute( $latency, $output1,$dayTimeConsumption, @rowArray1[0]);
			$sth2->finish();
			
			
			#sleep 1;

		}

		$sth1->finish();

		$returnValue = 0;

	};

	if ($@) {

		logEvent( 2, " Error 1 occured in fnRunCheck1() : $@ " );

	}

	return $returnValue;

}

sub fnGenerateItemList {

	my ( $hostName, $hostId ) = @_;
	my $returnValue  = 1;
	my $itemCounter  = 0;
	my $errorCounter = 0;

	eval {

		my $sql1 = <<DELIMITER1;

SELECT A.itemid,A.description,A.key_,A.delay FROM items A
WHERE
A.hostid=? AND A.status=0
AND A.type<>15 AND A.type<>3

 		
DELIMITER1


# we may be able to obtain calculate values and simple values too - if we query proxy configured as passive


		my $sth1 = $remoteMySqlDBH->prepare($sql1);

		$sth1->execute($hostId);

		my @rowArray1;

		$localSQLiteDBH->begin_work();

		while (
			( @rowArray1 =
				$sth1->fetchrow_array()
			)    ## loop through items found in remote Zabbix Mysql database
			&& ( $errorCounter == 0 )
		  )
		{

			logEvent( 1,
"Found Item on host $hostName : id @rowArray1[0], name '@rowArray1[1]', key '@rowArray1[2]'"
			);

			$itemCounter++;

my $processedItemKey=@rowArray1[2];


if ($processedItemKey =~ /\{\$/)			# key contains macros: resolve them
{


logEvent( 1,"Key $processedItemKey contains macros");

	my $sql1 = <<DELIMITER1;

SELECT macro,value FROM hostmacro
WHERE hostid=?
 		
DELIMITER1

		my $sth3 = $remoteMySqlDBH->prepare($sql1);

		$sth3->execute($hostId);

		my @rowArray2;

		
		while (
			( @rowArray2 =
				$sth3->fetchrow_array()
			)    ## loop through items found in remote Zabbix Mysql database
			&& ( $errorCounter == 0 )
		  )
		{

			logEvent( 1,"Macro '@rowArray2[0]' : '@rowArray2[1]'");
			

			$processedItemKey =~ s/\Q@rowArray2[0]\E/@rowArray2[1]/g;
	
		}
	
	
	logEvent( 1,"Resulting key after macros processed: $processedItemKey");
	
}



			my $sql2 = <<DELIMITER2;

INSERT INTO TA_LOG (DS_HOSTNAME,DS_ITEMNAME,DS_ITEMKEY,DL_ZDELAY) VALUES
(?,?,?,?) 
 		
DELIMITER2

			my $sth           = $localSQLiteDBH->prepare($sql2);
			my $rows_affected =
			  $sth->execute( $hostName, @rowArray1[1], $processedItemKey,@rowArray1[3] )
			  ;    # store general attributes of the item in TA_TEMPLATE_ITEMS
			$sth->finish()
			  ;    # end statement, release resources (not a transaction)

		}

		$sth1->finish();
		$localSQLiteDBH->commit();

	};

	if ($@) {

		logEvent( 2, " Error 1 occured in fnGenerateItemList() : $@ " );

		$errorCounter++;

	}

	if ( $errorCounter == 0 ) {
		logEvent( 1,
			"Exported $itemCounter items, encountered $errorCounter errors." );
	}

	$generalErrorCounter += $errorCounter;

	if ( $errorCounter > 0 ) {
		$returnValue = 0;
	}

	return $returnValue;

}

## get local Sqlite database creation SQL
sub getLocalDatabaseCreationStatement {
	my $result1 = <<DELIMITER1;




-- Table: TA_LOG
CREATE TABLE TA_LOG ( 
    DL_ID             INTEGER  PRIMARY KEY AUTOINCREMENT,
    DS_HOSTNAME       TEXT COLLATE 'NOCASE',
    DS_ITEMNAME       TEXT COLLATE 'NOCASE',
    DS_ITEMKEY       TEXT COLLATE 'NOCASE',
    DL_CHECKLATENCY       INTEGER,
    DS_CHECKOUTPUT       TEXT COLLATE 'NOCASE',
    DL_ZDELAY       INTEGER,
    DL_DAYTIMECONSUMPTION
    
         
);





DELIMITER1

	return $result1;

}

