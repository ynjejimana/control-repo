#!/usr/bin/perl
#### Monitoring SNMP Trap Messages (Maintenance utility)
#### Version 2.39
#### Written by: Premysl Botek (premysl.botek@lab.com)
##################################################################################
#### Note to future developers: when updating the version number of this script, please check/adjust version number setting in database it generates (look for 'THIS_DATABASE_VERSION' keyword) and also update compatibility info setting in database it generates ('COMPATIBILITY_INFO' keyword) - both in sub getNewDatabaseCreationStatement()
##################################################################################
## compiler declarations, environment setup

use v5.10;
use strict;
use Config::Simple;
use Data::Dumper;
use Net::OpenSSH;
use Time::Piece;
use Switch;
use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);
use DBI;

## DEPENDENT SETTINGS (values need to be reverified/set correctly during each installation - for this script to work and be integrated with the rest of functionality)
our $baseDir          = "/srv/zabbix/scripts/snmptrapmsgmonitoring";
our $logFileName      = "$baseDir/log.txt";
our $databaseFileName = "$baseDir/snmptrapmsgmonitoringdata.db";

my $loggingLevel = 2
  ; # 0 - no logging, 1 - log errors only, 2 - log everything (errors, warnings, debug info)
my $logOutput = 3
  ; # 1 - output to console, 2 - output to log file, 3 - output to both console and log file

## End - REQUIRED SETTINGS

my $dbh;
my $invalidCommandLine = 0;
my $appMode            = 0
  ; # 1 - diag-DUMPSTATS-READINGHISTORY, 2 - maintain-compactdatabase, 3 - diag-checkdatabaseintegrity, 4 - maintain-createnewdatabase, 5 - diag-DUMPSTATS, 6 - setting-get, 7 - setting-dumpall, 8 - setting-set
my $dumpLatestMode = 0;    # 0 - dump all, 1 - empty only, 2 - equal to a value

my $curr_seq_no;

my $thisModuleID =
  "DIAG-N-MAINTAIN";       # just for log file record identification purposes

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

		if ( uc( $ARGV[1] ) eq "CHECKDATABASEINTEGRITY" ) {
			$appMode            = 3;
			$invalidCommandLine = 0;

		}

		if ( uc( $ARGV[1] ) eq "DUMPSTATS" ) {

			if ( uc( $ARGV[2] ) eq "READINGSHISTORY" ) {

				$appMode            = 1;
				$invalidCommandLine = 0;

			}

			if ( ( $invalidCommandLine == 1 ) && defined( $ARGV[2] ) ) {
				$appMode            = 5;
				$curr_seq_no        = $ARGV[2];
				$invalidCommandLine = 0;

				if ( uc( $ARGV[3] ) eq "EMPTYONLY" ) {

					$dumpLatestMode = 1;

				}

			}

		}
	}

	if ( uc( $ARGV[0] ) eq "MAINTAIN" ) {

		$invalidCommandLine = 1;

		if ( uc( $ARGV[1] ) eq "COMPACTDATABASE" ) {
			$appMode            = 2;
			$invalidCommandLine = 0;

		}

		if ( uc( $ARGV[1] ) eq "CREATENEWDATABASE" ) {
			$appMode            = 4;
			$invalidCommandLine = 0;

		}

	}

}

if ($invalidCommandLine) {

	print <<USAGELABEL;
Invalid command line parameters
	
USAGE:	perl diag-n-maintain.pl <MAINTAIN|SETTING>

DIAG CHECKDATABASEINTEGRITY	- Checks integrity of snmptrapmsgmonitoringdata.db. Shall any integrity problems be detected, it is generally advised to generate a new clean database instead of trying to repairing it by compacting, editing in hex editor, etc.

MAINTAIN COMPACTDATABASE	- Compacts snmptrapmsgmonitoringdata.db. Cleans its unused space, repairs and defrags it. No need to do this regularly, the database file will not grow infinitely (old trap messages are deleted from retention and their space recycled) 

MAINTAIN CREATENEWDATABASE	- Creates fresh snmptrapmsgmonitoringdata.db with the default schema and fills it by default data (SQL statement is stored inside this script)

SETTING <GET> <setting_name>	- Retrieves the value of specified setting from TA_SETTINGS table 

SETTING <SET> <setting_name> <"value">			- Sets the value of specified setting in TA_SETTINGS table

SETTING DUMPALL			- Dumps all settings from TA_SETTINGS table + their descriptions	

USAGELABEL

	exit 0;
}

## main execution block

switch ($appMode) {
	case 1 {

		fnGetReadingHistory();

	}

	case 2 {

		fnCompactDatabase();

	}

	case 3 {

		fnCheckDatabaseIntegrity();

	}

	case 4 {

		fnCreateNewDatabase();

	}
	case 5 {

		fnDumpStats();

	}

	case 6 {

		fnGetSetting();

	}

	case 7 {

		fnDumpAllSettings();

	}

	case 8 {

		fnSetSetting();

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
		"Running integrity check on $databaseFileName, please wait..." );
	eval {

		# connect to database

		if ( !-f $databaseFileName ) {
			logEvent( 2, "Database file $databaseFileName does not exist" );
			exit 1;
		}

		$dbh = DBI->connect(
			"dbi:SQLite:dbname=$databaseFileName",
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

	logEvent( 1, "Compacting $databaseFileName, please wait..." );

	eval {

		# connect to database

		if ( !-f $databaseFileName ) {
			logEvent( 2, "Database file $databaseFileName does not exist" );
			exit 1;
		}

		$dbh = DBI->connect(
			"dbi:SQLite:dbname=$databaseFileName",
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

	if ( -f $databaseFileName ) {
		logEvent( 2,
"Unable to create new database. File $databaseFileName already exists"
		);
		exit 1;
	}

	eval {

		$dbh = DBI->connect(
			"dbi:SQLite:dbname=$databaseFileName",
			"", "", { RaiseError => 1, sqlite_allow_multiple_statements => 1, }
			, # important to be able to run multiple statements within one Do() run
		);

		my $ss1 = getNewDatabaseCreationStatement();
		$dbh->do($ss1);

		$dbh->disconnect();

		logEvent( 1, "Successfully created $databaseFileName" );

	};
	if ($@) {
		logEvent( 2, "Database error ($databaseFileName): $DBI::errstr" );
		exit 1;
	}

}

sub fnSetSetting {
	my $settingName;
	my $settingValue;
	if ( !-f $databaseFileName ) {
		logEvent( 2, "Database file $databaseFileName does not exist" );
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

		if ( !-f $databaseFileName ) {
			logEvent( 2, "Database file $databaseFileName does not exist" );
			exit 1;
		}

		$dbh = DBI->connect(
			"dbi:SQLite:dbname=$databaseFileName",
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

		if ( !-f $databaseFileName ) {
			logEvent( 2, "Database file $databaseFileName does not exist" );
			exit 1;
		}

		$dbh = DBI->connect(
			"dbi:SQLite:dbname=$databaseFileName",
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

		if ( !-f $databaseFileName ) {
			logEvent( 2, "Database file $databaseFileName does not exist" );
			exit 1;
		}

		$dbh = DBI->connect(
			"dbi:SQLite:dbname=$databaseFileName",
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

		if ( !-f $databaseFileName ) {
			logEvent( 2, "Database file $databaseFileName does not exist" );
			exit 1;
		}

		$dbh = DBI->connect(
			"dbi:SQLite:dbname=$databaseFileName",
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

	if ( !-f $databaseFileName ) {
		logEvent( 2, "Database file $databaseFileName does not exist" );
		exit 1;
	}

	eval {

		my $DBH = DBI->connect(
			"dbi:SQLite:dbname=$databaseFileName",
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

sub getNewDatabaseCreationStatement {
	my $result1 = <<DELIMITER1;


-- Table: TA_RECEIVED_TRAP_MSGS
CREATE TABLE TA_RECEIVED_TRAP_MSGS ( 
    DL_ID			INTEGER     PRIMARY KEY AUTOINCREMENT,    
    DT_TIMESTAMP	DATETIME    NOT NULL
                    	          DEFAULT (datetime('now','localtime')),
    
    DS_GUID					TEXT,    
    DS_SOURCE_IP			TEXT,
    DS_SOURCE_HOST			TEXT,
    DS_SEVERITY				TEXT,
    DS_NAME					TEXT,
    DS_ADD_INFO				TEXT,
    DS_OID					TEXT,            
    
    

    DS_ZABBIX_SENDER_FORWARDING_HOST					TEXT,
    DS_ZABBIX_SENDER_FORWARDING_QUEUE					TEXT,
    DL_ZABBIX_SENDER_FORWARDING_RESULT_CODE				INTEGER,
    DS_ZABBIX_SENDER_FORWARDING_ERROR_DESCRIPTION		TEXT,
    DL_RECOGNIZED_BY_SNMPTT								INTEGER
    														DEFAULT 0,
	DL_RECOGNIZED_ZABBIX_HOST							INTEGER
    														DEFAULT 0
    
);





CREATE TABLE TA_FORWARD_RULES_HOSTS ( 
    DL_ID					INTEGER     PRIMARY KEY AUTOINCREMENT,    
    DS_HOST_NAME			TEXT		NOT NULL
                              			UNIQUE,
    DL_DEFAULT_QUEUE_ID					INTEGER,
   
    FOREIGN KEY(DL_DEFAULT_QUEUE_ID) REFERENCES TA_FORWARD_RULES_QUEUES(DL_ID)
    
);




CREATE TABLE TA_FORWARD_RULES_QUEUES ( 
    DL_ID					INTEGER     PRIMARY KEY AUTOINCREMENT,    
    DS_QUEUE_NAME			TEXT		NOT NULL
                        		   		UNIQUE
);



CREATE TABLE TA_FORWARD_RULES_MESSAGES ( 
    DL_ID					INTEGER     PRIMARY KEY AUTOINCREMENT,    
    DS_MSG_OID				TEXT		NOT NULL
                        		   		COLLATE 'NOCASE',
    DL_HOST_ID				INTEGER,
    DL_QUEUE_ID				INTEGER,
    
    DS_RULE_ORIGIN			TEXT,
    
    FOREIGN KEY(DL_HOST_ID)	 REFERENCES TA_FORWARD_RULES_HOSTS(DL_ID),
    FOREIGN KEY(DL_QUEUE_ID) REFERENCES TA_FORWARD_RULES_QUEUES(DL_ID)
                        		   
);



CREATE TABLE TA_MAINTENANCE ( 
    DL_ID					INTEGER     PRIMARY KEY AUTOINCREMENT,    
    DS_HOST_IP				TEXT		NOT NULL
                        		   		COLLATE 'NOCASE',
    DT_START				DATETIME    NOT NULL
                    	          DEFAULT (datetime('now','localtime')),
	DT_END					DATETIME    NOT NULL
                    	          DEFAULT (datetime('now','localtime')),
	DS_NOTE					TEXT,
	DL_STATUS				INTEGER 	NOT NULL DEFAULT 1                   	          
                        		   
);



--##

CREATE INDEX idx_TA_MAINTENANCE1 ON TA_MAINTENANCE ( 
    DS_HOST_IP
);


CREATE INDEX idx_TA_MAINTENANCE2 ON TA_MAINTENANCE ( 
    DT_START
);


CREATE INDEX idx_TA_MAINTENANCE3 ON TA_MAINTENANCE ( 
    DT_END
);


CREATE INDEX idx_TA_MAINTENANCE4 ON TA_MAINTENANCE ( 
    DL_STATUS
);




CREATE INDEX idx_TA_RECEIVED_TRAP_MSGS1 ON TA_RECEIVED_TRAP_MSGS ( 
    DT_TIMESTAMP
);


CREATE INDEX idx_TA_RECEIVED_TRAP_MSGS2 ON TA_RECEIVED_TRAP_MSGS ( 
    DS_GUID
);


CREATE INDEX idx_TA_RECEIVED_TRAP_MSGS3 ON TA_RECEIVED_TRAP_MSGS ( 
    DS_SOURCE_IP
);


CREATE INDEX idx_TA_RECEIVED_TRAP_MSGS4 ON TA_RECEIVED_TRAP_MSGS ( 
    DS_SOURCE_HOST
);


CREATE INDEX idx_TA_RECEIVED_TRAP_MSGS5 ON TA_RECEIVED_TRAP_MSGS ( 
    DS_SEVERITY
);


CREATE INDEX idx_TA_RECEIVED_TRAP_MSGS6 ON TA_RECEIVED_TRAP_MSGS ( 
    DS_OID
);


CREATE INDEX idx_TA_RECEIVED_TRAP_MSGS7 ON TA_RECEIVED_TRAP_MSGS ( 
    DS_ZABBIX_SENDER_FORWARDING_HOST
);


CREATE INDEX idx_TA_RECEIVED_TRAP_MSGS8 ON TA_RECEIVED_TRAP_MSGS ( 
    DS_ZABBIX_SENDER_FORWARDING_QUEUE
);


CREATE INDEX idx_TA_RECEIVED_TRAP_MSGS9 ON TA_RECEIVED_TRAP_MSGS ( 
    DL_ZABBIX_SENDER_FORWARDING_RESULT_CODE
);


CREATE INDEX idx_TA_RECEIVED_TRAP_MSGS10 ON TA_RECEIVED_TRAP_MSGS ( 
    DL_RECOGNIZED_BY_SNMPTT
);


CREATE INDEX idx_TA_RECEIVED_TRAP_MSGS11 ON TA_RECEIVED_TRAP_MSGS ( 
    DL_RECOGNIZED_ZABBIX_HOST
);






--##



CREATE INDEX idx_TA_FORWARD_RULES_HOSTS1 ON TA_FORWARD_RULES_HOSTS ( 
    DS_HOST_NAME
);



--##



CREATE UNIQUE INDEX idx_TA_FORWARD_RULES_MESSAGES1 ON TA_FORWARD_RULES_MESSAGES ( 
    DS_MSG_OID,
    DL_HOST_ID
);


CREATE INDEX idx_TA_FORWARD_RULES_MESSAGES2 ON TA_FORWARD_RULES_MESSAGES ( 
    DL_HOST_ID
);


CREATE INDEX idx_TA_FORWARD_RULES_MESSAGES3 ON TA_FORWARD_RULES_MESSAGES ( 
    DL_QUEUE_ID
);


CREATE INDEX idx_TA_FORWARD_RULES_MESSAGES4 ON TA_FORWARD_RULES_MESSAGES ( 
    DS_MSG_OID
);


CREATE INDEX idx_TA_FORWARD_RULES_MESSAGES5 ON TA_FORWARD_RULES_MESSAGES ( 
    DS_RULE_ORIGIN
);



--##



-- Table: TA_SETTINGS
CREATE TABLE TA_SETTINGS ( 
    DS_KEY         TEXT PRIMARY KEY
                        COLLATE 'NOCASE',
    DS_VALUE       TEXT,
    DS_DESCRIPTION TEXT 
);


INSERT INTO [TA_SETTINGS] ([DS_KEY], [DS_VALUE], [DS_DESCRIPTION]) VALUES ('DATA_RETENTION_PERIOD', 0, 'unit:days;default:0;purpose: defines how old trap event data should be deleted from the database, if set to 0, no history data is deleted from database');
INSERT INTO [TA_SETTINGS] ([DS_KEY], [DS_VALUE], [DS_DESCRIPTION]) VALUES ('LAST_DATA_RETENTION_LAST_MAINTENANCE_TIMESTAMP', '', 'purpose: internal value that snmptt_helper.pl checks to see whether it should run maintenance procedure');
INSERT INTO [TA_SETTINGS] ([DS_KEY], [DS_VALUE], [DS_DESCRIPTION]) VALUES ('DATA_RETENTION_LAST_MAINTENANCE_INTERVAL', 5, 'unit:minutes;default:5;purpose: sets how often is maintenance procedure executed by snmptt_helper.pl - this interval prevents to have it executed every time when it starts');
INSERT INTO [TA_SETTINGS] ([DS_KEY], [DS_VALUE], [DS_DESCRIPTION]) VALUES ('WEB_APP_URL', 'http://172.16.40.172/snmptrapmsgmonitoring/', 'Specifies full address of the PHP scripts. Must be located on the same machine as the core database');
INSERT INTO [TA_SETTINGS] ([DS_KEY], [DS_VALUE], [DS_DESCRIPTION]) VALUES ('ZABBIX_VERSION_MAJOR', '1', 'Specifies major version number of Zabbix system this trapper is to be integrated with. Supported values: 1 and 2');
INSERT INTO [TA_SETTINGS] ([DS_KEY], [DS_VALUE], [DS_DESCRIPTION]) VALUES ('THIS_DATABASE_VERSION', '2.31', 'just to keep the track of this database changes');
INSERT INTO [TA_SETTINGS] ([DS_KEY], [DS_VALUE], [DS_DESCRIPTION]) VALUES ('COMPATIBILITY_INFO', '
This info has been generated by diag-n-maintain.pl version 2.31:
* compatible with diag-n-maintain.pl versions 2.31.x
* compatible with snmptt-helper.pl versions 2.31.x
* compatible with get-data.pl versions 2.31.x
* compatible with snmptrappergui.php versions 2.31.x
* tested as per https://wiki.lab.com.au/display/ENG/Monitoring+SNMP+Trap+Messages+V2#MonitoringSNMPTrapMessagesV2-20.1SOLUTIONTESTINGRESULTS 
Please report any inconsistencies to Premysl Botek / Premek at premysl.botek(at)lab.com. Ta!
', '');


INSERT INTO [TA_FORWARD_RULES_QUEUES] ([DS_QUEUE_NAME]) VALUES ('SNMPTrap-Queue1');
INSERT INTO [TA_FORWARD_RULES_QUEUES] ([DS_QUEUE_NAME]) VALUES ('SNMPTrap-Queue2');
INSERT INTO [TA_FORWARD_RULES_QUEUES] ([DS_QUEUE_NAME]) VALUES ('SNMPTrap-Queue3');


INSERT INTO [TA_FORWARD_RULES_HOSTS] ([DS_HOST_NAME],[DL_DEFAULT_QUEUE_ID]) VALUES ('UNLISTED_HOSTS',1);


INSERT INTO TA_FORWARD_RULES_MESSAGES
(DS_MSG_OID,DL_HOST_ID,DL_QUEUE_ID,DS_RULE_ORIGIN) VALUES ('UNLISTED_MESSAGES',1,1,'system');



DELIMITER1

	return $result1;

}
