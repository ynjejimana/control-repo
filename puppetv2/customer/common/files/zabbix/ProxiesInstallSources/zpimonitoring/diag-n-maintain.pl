#!/usr/bin/perl
#### Zabbix Proxy Internal Monitoring (Maintenance utility)
#### Version 1.14
#### Written by: Premysl Botek (premysl.botek@lab.com)
##################################################################################
#### Note to future developers: when updating the version number of this script, please check/adjust version number setting in database it generates (look for 'THIS_DATABASE_VERSION' keyword) and also update compatibility info setting in database it generates ('COMPATIBILITY_INFO' keyword) - both in sub getNewDatabaseCreationStatement1()
##################################################################################
## compiler declarations, environment setup

use v5.10;
use strict;
use Config::Simple;
use Data::Dumper;
no if $] >= 5.018, 'warnings', "experimental::smartmatch";

use Time::Piece;

#use Switch;			# do not use this module! causes very poor script performance
use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);
use DBI;
use DBD::SQLite;

## DEPENDENT SETTINGS (values need to be reverified/set correctly during each installation - for this script to work and be integrated with the rest of functionality)

our $zpimBaseDir = "/srv/zabbix/scripts/zpimonitoring";

my $loggingLevel = 2
  ; # 0 - no logging, 1 - log errors only, 2 - log everything (errors, warnings, debug info)
my $logOutput = 3
  ; # 1 - output to console, 2 - output to log file, 3 - output to both console and log file

## End - REQUIRED SETTINGS

our $logFileName           = "$zpimBaseDir/log.txt";
our $zpimDatabase1FileName = "$zpimBaseDir/zpimonitoring.db";

my $dbh;
my $invalidCommandLine = 0;
my $appMode            = 0
  ; # 1 - diag-DUMPSTATS-READINGHISTORY, 2 - maintain-compactdatabase, 3 - diag-checkdatabaseintegrity, 4 - maintain-createnewdatabase, 5 - diag-DUMPSTATS, 6 - setting-get, 7 - setting-dumpall, 8 - setting-set
my $dumpLatestMode = 0;    # 0 - dump all, 1 - empty only, 2 - equal to a value

my $curr_seq_no;

my $thisModuleID =
  "DIAG-N-MAINTAIN";       # just for log file record identification purposes

my $zpimZAgentPerf1Tracing_dataRetentionPeriod1 = 30;
my $zpimZAgentPerf1Tracing_dataRetentionPeriod2 = 24;
my $zpimZAgentPerf1Tracing_dataRetentionPeriod3 = 60;

## program entry point
## program initialization

if ( $#ARGV < 1 ) {
	$invalidCommandLine = 1;
}
else {

	$invalidCommandLine = 1;

	if ( uc( $ARGV[0] ) eq "SETTING" ) {

		if ( uc( $ARGV[1] ) eq "GET" ) {
			$appMode            = 6;
			$invalidCommandLine = 0;

		}

		if ( uc( $ARGV[1] ) eq "SET" ) {
			$appMode            = 8;
			$invalidCommandLine = 0;

		}

		if ( uc( $ARGV[1] ) eq "DUMPALL" ) {
			$appMode            = 7;
			$invalidCommandLine = 0;

		}

	}

	if ( uc( $ARGV[0] ) eq "DIAG" ) {

		if ( uc( $ARGV[1] ) eq "CHECKDATABASESINTEGRITY" ) {
			$appMode            = 3;
			$invalidCommandLine = 0;

		}

		if ( uc( $ARGV[1] ) eq "DUMPSTATS" ) {

			if ( uc( $ARGV[2] ) eq "1" ) {    #  zpimZAgentPerf1 diagnostics

				if ( uc( $ARGV[3] ) eq "1" )
				{    #  dump zpimZAgentPerf1 sessions in progress

					$appMode            = 9;
					$invalidCommandLine = 0;

				}

				if ( uc( $ARGV[3] ) eq "2" )
				{  #  dump zpimZAgentPerf1 sessions completed in last 30 seconds

					$appMode            = 10;
					$invalidCommandLine = 0;

				}
				if ( uc( $ARGV[3] ) eq "3" )
				{  #  dump zpimZAgentPerf1 sessions terminated by Zagent timeout

					$appMode            = 11;
					$invalidCommandLine = 0;

				}

			}

		}
	}

	if ( uc( $ARGV[0] ) eq "MAINTAIN" ) {

		$invalidCommandLine = 1;

		if ( uc( $ARGV[1] ) eq "COMPACTDATABASES" ) {
			$appMode            = 2;
			$invalidCommandLine = 0;

		}

		if ( uc( $ARGV[1] ) eq "CREATENEWDATABASE" ) {
			$appMode            = 4;
			$invalidCommandLine = 0;

		}

		if ( uc( $ARGV[1] ) eq "1" ) {    #  zpimZAgentPerf1 maintenance

			if ( uc( $ARGV[2] ) eq "1" ) {   #  maintain zpimZAgentPerf1 anchors

				$appMode            = 12;
				$invalidCommandLine = 0;

			}

		}

	}

}

if ($invalidCommandLine) {

	print <<USAGELABEL;
Invalid command line parameters
	
USAGE:	perl diag-n-maintain.pl <MAINTAIN|SETTING>

DIAG CHECKDATABASESINTEGRITY	- Checks integrity of snmptrapmsgmonitoringdata.db. Shall any integrity problems be detected, it is generally advised to generate a new clean database instead of trying to repairing it by compacting, editing in hex editor, etc.

MAINTAIN COMPACTDATABASES	- Compacts snmptrapmsgmonitoringdata.db. Cleans its unused space, repairs and defrags it. No need to do this regularly, the database file will not grow infinitely (old trap messages are deleted from retention and their space recycled) 

MAINTAIN CREATENEWDATABASESET	- Creates fresh snmptrapmsgmonitoringdata.db with the default schema and fills it by default data (SQL statement is stored inside this script)

SETTING <GET> <setting_name>	- Retrieves the value of specified setting from TA_SETTINGS table 

SETTING <SET> <setting_name> <"value">			- Sets the value of specified setting in TA_SETTINGS table

SETTING DUMPALL			- Dumps all settings from TA_SETTINGS table + their descriptions	

USAGELABEL

	exit 0;
}

## main execution block

given ($appMode) {
	when (1) {

		fnGetReadingHistory();

	}

	when (2) {

		fnCompactDatabase();

	}

	when (3) {

		fnCheckDatabaseIntegrity();

	}

	when (4) {

		fnCreateNewDatabase();

	}
	when (5) {

		fnDumpStats();

	}

	when (6) {

		fnGetSetting();

	}

	when (7) {

		fnDumpAllSettings();

	}

	when (8) {

		fnSetSetting();

	}

	when (9) {

		ZpimZAgentPerf1_fnDumpStats1();

	}
	when (10) {

		ZpimZAgentPerf1_fnDumpStats2();

	}

	when (11) {

		ZpimZAgentPerf1_fnDumpStats3();

	}

	when (12) {

		fnMaintainDataRetention1()
		  ; # keep the database file small by deleting unneded records (this is complemented by DUMPSTATS 1,2,3 which maintains always before it retrieves statistics)

	}

}

## end - main execution block

##  program exit point	###########################################################################

## service functions

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

sub fnCheckDatabaseIntegrity {
	logEvent( 1,
		"Running integrity check on $zpimDatabase1FileName, please wait..." );
	eval {

		# connect to database

		if ( !-f $zpimDatabase1FileName ) {
			logEvent( 2,
				"Database file $zpimDatabase1FileName does not exist" );
			exit 1;
		}

		$dbh = DBI->connect(
			"dbi:SQLite:dbname=$zpimDatabase1FileName",
			"", "", { RaiseError => 1 },
		);
		my $sth = $dbh->prepare("pragma integrity_check");

		$sth->execute();

		my @rowArray;
		while ( @rowArray = $sth->fetchrow_array() ) {

			print "results : @rowArray[0]\n";

		}

		$sth->finish();   # end statement, release resources (not a transaction)

		$dbh->disconnect();

		logEvent( 1, "Integrity check finished." );

	};

	if ($@) {
		logEvent( 2, "Database error: $DBI::errstr" );
		exit 1;
	}

}

sub fnCompactDatabase {

	logEvent( 1, "Compacting $zpimDatabase1FileName, please wait..." );

	eval {

		# connect to database

		if ( !-f $zpimDatabase1FileName ) {
			logEvent( 2,
				"Database file $zpimDatabase1FileName does not exist" );
			exit 1;
		}

		$dbh = DBI->connect(
			"dbi:SQLite:dbname=$zpimDatabase1FileName",
			"", "", { RaiseError => 1 },
		);

		$dbh->do('VACUUM');
		$dbh->disconnect();
		logEvent( 1, "Compacting successfully completed." );

	};

	if ($@) {
		logEvent( 2, "Database error: $DBI::errstr" );
		exit 1;
	}

}

sub fnCreateNewDatabase {

	if ( -f $zpimDatabase1FileName ) {
		logEvent( 2,
"Unable to create new database. File $zpimDatabase1FileName already exists"
		);
		exit 1;
	}

	eval {

		$dbh = DBI->connect(
			"dbi:SQLite:dbname=$zpimDatabase1FileName",
			"", "", { RaiseError => 1, sqlite_allow_multiple_statements => 1, }
			, # important to be able to run multiple statements within one Do() run
		);

		my $ss1 = getNewDatabaseCreationStatement1();

		#print "ssss:".$ss1;

		#print "\n result $@";

		$dbh->do($ss1);

		undef $dbh;

		logEvent( 1, "Successfully created $zpimDatabase1FileName" );

	};
	if ($@) {
		logEvent( 2, "Database error ($zpimDatabase1FileName): $DBI::errstr" );
		logEvent( 2, "Database error ($zpimDatabase1FileName): $@" );

		exit 1;
	}

}

sub fnSetSetting {
	my $settingName;
	my $settingValue;
	if ( !-f $zpimDatabase1FileName ) {
		logEvent( 2, "Database file $zpimDatabase1FileName does not exist" );
		exit 1;
	}

	$settingName  = $ARGV[2];
	$settingValue = $ARGV[3];

	if ( writeSettingToDatabase1( $settingName, $settingValue ) ) {

		logEvent( 1, "Successfully set $settingName = \"$settingValue\"" );

	}

}

sub fnGetSetting {

	my $settingValue;

	eval {

		# connect to database

		if ( !-f $zpimDatabase1FileName ) {
			logEvent( 2,
				"Database file $zpimDatabase1FileName does not exist" );
			exit 1;
		}

		$dbh = DBI->connect(
			"dbi:SQLite:dbname=$zpimDatabase1FileName",
			"", "", { RaiseError => 1 },
		);

		readSettingFromDatabase1( $ARGV[2], \$settingValue ) or exit 1;

		if ( !defined($settingValue) ) {
			logEvent( 2, "$ARGV[2] does not exist in TA_SETTINGS" );

		}
		else {
			print "$ARGV[2] = \"$settingValue\"\n";

		}

		$dbh->disconnect();

	};
	if ($@) {
		logEvent( 2, "Database error: $DBI::errstr" );
		exit 1;
	}

}

sub fnDumpStats {

	eval {

		# connect to database

		if ( !-f $zpimDatabase1FileName ) {
			logEvent( 2,
				"Database file $zpimDatabase1FileName does not exist" );
			exit 1;
		}

		$dbh = DBI->connect(
			"dbi:SQLite:dbname=$zpimDatabase1FileName",
			"", "", { RaiseError => 1 },
		);

		my $sql1 =
"SELECT DT_TIMESTAMP,DS_STATNAME,DS_VALUE,DL_GLOBAL_SEQ_NUMBER FROM TA_COLLECTED_DATA WHERE DL_GLOBAL_SEQ_NUMBER=$curr_seq_no ORDER BY DS_STATNAME";

		my $sth = $dbh->prepare($sql1);

		$sth->execute();

		my @rowArray;
		my $rowCounter      = 0;
		my $emptyRowCounter = 0;
		while ( @rowArray = $sth->fetchrow_array() ) {

			if ( $dumpLatestMode == 0 ) {    # dump all

				print
"[GLOBAL_SEQ_NUMBER=@rowArray[3]] @rowArray[0]  @rowArray[1] = @rowArray[2]\n";
			}

			if ( ( $dumpLatestMode == 1 ) and ( @rowArray[2] eq "" ) )
			{                                # dump empty only

				print
"[GLOBAL_SEQ_NUMBER=@rowArray[3]] @rowArray[0]  @rowArray[1] = @rowArray[2]\n";
			}

			$rowCounter++;
			if ( @rowArray[2] eq "" ) { $emptyRowCounter++; }
		}

		$sth->finish();   # end statement, release resources (not a transaction)
		$dbh->disconnect();
		logEvent( 1, "Found $rowCounter items, $emptyRowCounter empty." );

	};

	if ($@) {
		logEvent( 2, "Database error: $DBI::errstr" );
		exit 1;
	}

}

sub fnDumpAllSettings {

	eval {

		# connect to database

		if ( !-f $zpimDatabase1FileName ) {
			logEvent( 2,
				"Database file $zpimDatabase1FileName does not exist" );
			exit 1;
		}

		$dbh = DBI->connect(
			"dbi:SQLite:dbname=$zpimDatabase1FileName",
			"", "", { RaiseError => 1 },
		);

		my $sql1 =
"SELECT DS_KEY,DS_VALUE,DS_DESCRIPTION FROM TA_SETTINGS ORDER BY DS_KEY,DS_VALUE";

		my $sth = $dbh->prepare($sql1);

		$sth->execute();

		my @rowArray;
		my $rowCounter = 0;

		while ( @rowArray = $sth->fetchrow_array() ) {

			my $strDescription = "";
			if ( !( @rowArray[2] eq "" ) ) {
				$strDescription = "[@rowArray[2]]";
			}

			print "@rowArray[0] = \"@rowArray[1]\" $strDescription\n";

			$rowCounter++;

		}

		$sth->finish();   # end statement, release resources (not a transaction)
		$dbh->disconnect();
		print("Listed $rowCounter settings.\n");

	};

	if ($@) {
		logEvent( 2, "Database error: $DBI::errstr" );
		exit 1;
	}

}

sub fnGetReadingHistory {

	eval {

		logEvent( 1, "Dumping last 100 history records." );

		# connect to database

		if ( !-f $zpimDatabase1FileName ) {
			logEvent( 2,
				"Database file $zpimDatabase1FileName does not exist" );
			exit 1;
		}

		$dbh = DBI->connect(
			"dbi:SQLite:dbname=$zpimDatabase1FileName",
			"", "", { RaiseError => 1 },
		);

		my $sql1 =
"SELECT * FROM (SELECT DS_STATNAME,DT_TIMESTAMP,DL_GLOBAL_SEQ_NUMBER,DL_APP_INSTANCE_SEQ_NUMBER,DL_ID FROM TA_COLLECTED_DATA WHERE (DS_STATNAME LIKE 'metadata:seqheader:%') OR (DS_STATNAME LIKE 'metadata:seqfooter:%') ORDER BY DL_ID DESC LIMIT 100) NESTED1 ORDER BY NESTED1.DL_ID";

		my $sth = $dbh->prepare($sql1);

		$sth->execute();

		my @rowArray;
		my $rowCounter = 0;

		while ( @rowArray = $sth->fetchrow_array() ) {

			if ( @rowArray[0] =~ /seqfooter/ ) {

				print
"@rowArray[1] [GLOBAL_SEQ_NUMBER=@rowArray[2],CLUSTER_SEQ_NUMBER=@rowArray[3]] :  @rowArray[0]\n";
			}
			else {

				print
"@rowArray[1] [GLOBAL_SEQ_NUMBER=@rowArray[2],CLUSTER_SEQ_NUMBER=@rowArray[3]] : @rowArray[0]\n";

			}

			$rowCounter++;

		}

		$sth->finish();   # end statement, release resources (not a transaction)
		$dbh->disconnect();
		logEvent( 1, "Found $rowCounter items." );

	};

	if ($@) {
		logEvent( 2, "Database error: $DBI::errstr" );
		exit 1;
	}

}

sub writeSettingToDatabase1 {
	my ( $key1, $value1 ) = @_;
	my $subresult = 0;
	my $DBH;

	if ( !-f $zpimDatabase1FileName ) {
		logEvent( 2, "Database file $zpimDatabase1FileName does not exist" );
		exit 1;
	}

	eval {

		my $DBH = DBI->connect(
			"dbi:SQLite:dbname=$zpimDatabase1FileName",
			"", "", { RaiseError => 1 },
		);

		my $sql1 =
		  "UPDATE TA_SETTINGS SET DS_VALUE=\"$value1\" WHERE DS_KEY=\"$key1\"";

		my $sth = $DBH->prepare($sql1);

		my $rows_affected = $sth->execute();

		$sth->finish();   # end statement, release resources (not a transaction)

		if ( $rows_affected == 1 ) {

			$subresult = 1;

		}
		else {

			logEvent( 2,
"Error 1 occured in writeSettingToDatabase1(): Setting '$key1' does not exist."
			);

		}

		$DBH->disconnect();

		return
		  ; # returns only from this eval block, not from the sub. Very "smart" feature of Perl...

	};

	if ($@) {

		logEvent( 2, "Error 2 occured in writeSettingToDatabase1(): $@" );

	}

	return $subresult;

}

sub ZpimZAgentPerf1_fnDumpStats1 {

	eval {

		# connect to database

		if ( !-f $zpimDatabase1FileName ) {
			logEvent( 2,
				"Database file $zpimDatabase1FileName does not exist" );
			exit 1;
		}

		$dbh = DBI->connect(
			"dbi:SQLite:dbname=$zpimDatabase1FileName",
			"", "", { RaiseError => 1 },
		);

	};

	if ($@) {
		logEvent( 2, "Error 1 occured in ZpimZAgentPerf1_fnDumpStats1(): $@" );
		exit 1;
	}

	maintainDataRetention1();

	eval {

		my $sql1 =
"SELECT DL_ID,DT_TIMESTAMP,DL_ANCHOR_STATUS,DL_ANCHOR_DURATION,DS_FUNCTIONALITY_GUID,DS_SESSION_ID,DS_VAL2,DS_VAL1 FROM TA_ZAGENT_PERF_1 WHERE DL_ANCHOR_STATUS=1";

		my $sth = $dbh->prepare($sql1);

		$sth->execute();

		my @rowArray;
		my $rowCount = 0;

		print "ZpimZAgentPerf1 sessions in progress:\n";

		print
"DL_ID | DT_TIMESTAMP | DL_ANCHOR_STATUS | DL_ANCHOR_DURATION[ms] | DS_FUNCTIONALITY_GUID | DS_SESSION_ID(pid) | DS_VAL2(result value) | DS_VAL1(command line) \n";

		while ( @rowArray = $sth->fetchrow_array() ) {

			print
"@rowArray[0] | @rowArray[1] | @rowArray[2] | @rowArray[3] | @rowArray[4] | @rowArray[5] | @rowArray[6] | @rowArray[7] \n";

			$rowCount++;

		}

		print "$rowCount rows found\n";

		$sth->finish();   # end statement, release resources (not a transaction)
		                  #$dbh->disconnect();

	};

	if ($@) {
		logEvent( 2, "Error 2 occured in ZpimZAgentPerf1_fnDumpStats1(): $@" );
		exit 1;
	}

	eval {

		undef $dbh;

	};

	if ($@) {
		logEvent( 2, "Error 3 occured in ZpimZAgentPerf1_fnDumpStats1(): $@" );
		exit 1;
	}

}

sub ZpimZAgentPerf1_fnDumpStats2 {

	eval {

		# connect to database

		if ( !-f $zpimDatabase1FileName ) {
			logEvent( 2,
				"Database file $zpimDatabase1FileName does not exist" );
			exit 1;
		}

		$dbh = DBI->connect(
			"dbi:SQLite:dbname=$zpimDatabase1FileName",
			"", "", { RaiseError => 1 },
		);

	};

	if ($@) {
		logEvent( 2, "Error 1 occured in ZpimZAgentPerf1_fnDumpStats2(): $@" );
		exit 1;
	}

	maintainDataRetention1();

	eval {

		my $sql1 =
"SELECT DL_ID,DT_TIMESTAMP,DL_ANCHOR_STATUS,DL_ANCHOR_DURATION,DS_FUNCTIONALITY_GUID,DS_SESSION_ID,DS_VAL2,DS_VAL1 FROM TA_ZAGENT_PERF_1 WHERE DL_ANCHOR_STATUS=2";

		my $sth = $dbh->prepare($sql1);

		$sth->execute();

		my @rowArray;
		my $rowCount = 0;

		print
"ZpimZAgentPerf1 sessions completed in last $zpimZAgentPerf1Tracing_dataRetentionPeriod3 seconds:\n";

		print
"DL_ID | DT_TIMESTAMP | DL_ANCHOR_STATUS | DL_ANCHOR_DURATION[ms] | DS_FUNCTIONALITY_GUID | DS_SESSION_ID(pid) | DS_VAL2(result value) | DS_VAL1(command line) \n";

		while ( @rowArray = $sth->fetchrow_array() ) {

			print
"@rowArray[0] | @rowArray[1] | @rowArray[2] | @rowArray[3] | @rowArray[4] | @rowArray[5] | @rowArray[6] | @rowArray[7] \n";

			$rowCount++;

		}

		print "$rowCount rows found\n";

		$sth->finish();   # end statement, release resources (not a transaction)
		                  #$dbh->disconnect();

	};

	if ($@) {
		logEvent( 2, "Error 2 occured in ZpimZAgentPerf1_fnDumpStats2(): $@" );
		exit 1;
	}

	eval {

		undef $dbh;

	};

	if ($@) {
		logEvent( 2, "Error 3 occured in ZpimZAgentPerf1_fnDumpStats2(): $@" );
		exit 1;
	}

}

sub ZpimZAgentPerf1_fnDumpStats3 {

	eval {

		# connect to database

		if ( !-f $zpimDatabase1FileName ) {
			logEvent( 2,
				"Database file $zpimDatabase1FileName does not exist" );
			exit 1;
		}

		$dbh = DBI->connect(
			"dbi:SQLite:dbname=$zpimDatabase1FileName",
			"", "", { RaiseError => 1 },
		);

	};

	if ($@) {
		logEvent( 2, "Error 1 occured in ZpimZAgentPerf1_fnDumpStats3(): $@" );
		exit 1;
	}

	maintainDataRetention1();

	eval {

		my $sql1 =
"SELECT DL_ID,DT_TIMESTAMP,DL_ANCHOR_STATUS,DL_ANCHOR_DURATION,DS_FUNCTIONALITY_GUID,DS_SESSION_ID,DS_VAL2,DS_VAL1 FROM TA_ZAGENT_PERF_1 WHERE DL_ANCHOR_STATUS=3";

		my $sth = $dbh->prepare($sql1);

		$sth->execute();

		my @rowArray;
		my $rowCount = 0;

		print
"ZpimZAgentPerf1 sessions zpimZAgentPerf1 sessions terminated by Zagent timeout in last $zpimZAgentPerf1Tracing_dataRetentionPeriod2 hours:\n";

		print
"DL_ID | DT_TIMESTAMP | DL_ANCHOR_STATUS | DL_ANCHOR_DURATION[ms] | DS_FUNCTIONALITY_GUID | DS_SESSION_ID(pid) | DS_VAL2(result value) | DS_VAL1(command line) \n";

		while ( @rowArray = $sth->fetchrow_array() ) {

			print
"@rowArray[0] | @rowArray[1] | @rowArray[2] | @rowArray[3] | @rowArray[4] | @rowArray[5] | @rowArray[6] | @rowArray[7] \n";

			$rowCount++;

		}

		print "$rowCount rows found\n";

		$sth->finish();   # end statement, release resources (not a transaction)
		                  #$dbh->disconnect();

	};

	if ($@) {
		logEvent( 2, "Error 2 occured in ZpimZAgentPerf1_fnDumpStats3(): $@" );
		exit 1;
	}

	eval {

		undef $dbh;

	};

	if ($@) {
		logEvent( 2, "Error 3 occured in ZpimZAgentPerf1_fnDumpStats3(): $@" );
		exit 1;
	}

}

sub maintainDataRetention1 {
	my $returnValue = 0;
	my $dataRetentionPeriod;
	my $rowsAffected;
	my $zpimSql1;
	my $zpimSth1;

   #	readSettingFromDatabase1( "DATA_RETENTION_PERIOD1", \$dataRetentionPeriod )
   #	  or return $returnValue;
   #
   #	if ( !defined($dataRetentionPeriod) ) {
   #		logEvent( 2, "DATA_RETENTION_PERIOD1 does not exist in TA_SETTINGS" );
   #		return $returnValue;
   #
   #	}

	## maintain database
	eval {

		# delete all rows that are older than 1 day (to keep database small)
		$zpimSql1 =
"DELETE FROM TA_ZAGENT_PERF_1 WHERE DATETIME(DT_TIMESTAMP)<DATETIME(DATETIME( 'now' , 'localtime' ),'-"
		  . $zpimZAgentPerf1Tracing_dataRetentionPeriod1
		  . " hour')";
		$zpimSth1 = $dbh->prepare($zpimSql1);

		$zpimSth1->execute();
	};

	if ($@) {
		logEvent( 2, "Error 1 in maintainDataRetention1(): $@" );
		return $returnValue;
	}
	eval {

# delete all anchors that have valid exit flag(2) and are older than $zpimZAgentPerf1Tracing_dataRetentionPeriod3 seconds - to keep/report only those which have not ended with exit flag (were terminated)

		$zpimSql1 =
"DELETE FROM TA_ZAGENT_PERF_1 WHERE DL_ANCHOR_STATUS=2 AND DATETIME(DT_TIMESTAMP)<DATETIME(DATETIME( 'now' , 'localtime' ),'-"
		  . $zpimZAgentPerf1Tracing_dataRetentionPeriod3
		  . " second')";
		$zpimSth1 = $dbh->prepare($zpimSql1);

		$zpimSth1->execute();
	};

	if ($@) {
		logEvent( 2, "Error 2 in maintainDataRetention1(): $@" );
		return $returnValue;
	}

	eval {

# mark all active anchors that are older than $zpimZAgentPerf1Tracing_dataRetentionPeriod2 seconds as terminated ($zpimZAgentPerf1Tracing_dataRetentionPeriod2 must be the smaller value of StartAgents and StartPollers)

		$zpimSql1 =
"UPDATE TA_ZAGENT_PERF_1 SET DL_ANCHOR_STATUS=3 WHERE DL_ANCHOR_STATUS=1 AND DATETIME(DT_TIMESTAMP)<DATETIME(DATETIME( 'now' , 'localtime' ),'-"
		  . $zpimZAgentPerf1Tracing_dataRetentionPeriod2
		  . " second')";
		$zpimSth1 = $dbh->prepare($zpimSql1);

		$zpimSth1->execute();
	};

	if ($@) {
		logEvent( 2, "Error 3 in maintainDataRetention1(): $@" );
		return $returnValue;
	}

	#logEvent( 1, "maintainDataRetention1() - result: " . $returnValue );
	return $returnValue;

}

sub fnMaintainDataRetention1 {

	eval {

		# connect to database

		if ( !-f $zpimDatabase1FileName ) {
			logEvent( 2,
				"Database file $zpimDatabase1FileName does not exist" );
			exit 1;
		}

		$dbh = DBI->connect(
			"dbi:SQLite:dbname=$zpimDatabase1FileName",
			"", "", { RaiseError => 1 },
		);

	};

	if ($@) {
		logEvent( 2, "Error 1 occured in fnMaintainDataRetention1(): $@" );
		exit 1;
	}

	maintainDataRetention1();

	eval {

		undef $dbh;

	};

	if ($@) {
		logEvent( 2, "Error 2 occured in fnMaintainDataRetention1(): $@" );
		exit 1;
	}

}

sub getNewDatabaseCreationStatement1 {
	my $result1 = <<DELIMITER1;



-- Table: TA_SETTINGS
CREATE TABLE TA_SETTINGS ( 
    DS_KEY         TEXT PRIMARY KEY
                        COLLATE 'NOCASE',
    DS_VALUE       TEXT,
    DS_DESCRIPTION TEXT 
);

INSERT INTO [TA_SETTINGS] ([DS_KEY], [DS_VALUE], [DS_DESCRIPTION]) VALUES ('DATA_RETENTION_PERIOD1', 30, 'unit:seconds;default:30;purpose: defines how old session anchors should be deleted from table TA_ZAGENT_PERF_1');
INSERT INTO [TA_SETTINGS] ([DS_KEY], [DS_VALUE], [DS_DESCRIPTION]) VALUES ('THIS_DATABASE_VERSION', 1.0, 'just to keep the track of this database changes');
INSERT INTO [TA_SETTINGS] ([DS_KEY], [DS_VALUE], [DS_DESCRIPTION]) VALUES ('COMPATIBILITY_INFO', '
This info has been generated by diag-n-maintain.pl version 1.0:
* compatible with diag-n-maintain.pl versions 1.0.x
* compatible with get-data.pl versions 1.0.x 
Please report any inconsistencies to Premysl Botek / Premek at premysl.botek(at)lab.com. Ta!
', '');




-- Table: TA_ZAGENT_PERF_1
CREATE TABLE TA_ZAGENT_PERF_1 ( 
    DL_ID                 INTEGER  PRIMARY KEY AUTOINCREMENT,
    DT_TIMESTAMP          DATETIME NOT NULL
                                   DEFAULT ( datetime( 'now', 'localtime' )  ),
	DL_ANCHOR_STATUS			INTEGER DEFAULT 0,
	DL_ANCHOR_DURATION			INTEGER,
	DS_FUNCTIONALITY_GUID		TEXT,
	DS_SESSION_ID				TEXT,
	DL_VAL1						INTEGER,
	DL_VAL2						INTEGER,
	DS_VAL1						TEXT,
	DS_VAL2						TEXT
);

CREATE INDEX idx_TA_ZAGENT_PERF_1_1 ON TA_ZAGENT_PERF_1 ( 
    DT_TIMESTAMP
);

CREATE INDEX idx_TA_ZAGENT_PERF_1_2 ON TA_ZAGENT_PERF_1 ( 
    DS_FUNCTIONALITY_GUID
);

CREATE INDEX idx_TA_ZAGENT_PERF_1_3 ON TA_ZAGENT_PERF_1 ( 
    DS_SESSION_ID
);

CREATE INDEX idx_TA_ZAGENT_PERF_1_4 ON TA_ZAGENT_PERF_1 ( 
    DL_VAL1
);

CREATE INDEX idx_TA_ZAGENT_PERF_1_5 ON TA_ZAGENT_PERF_1 ( 
    DS_VAL1
);



DELIMITER1

	return $result1;

}

