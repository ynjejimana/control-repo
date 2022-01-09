#!/usr/bin/perl
#### Monitoring SNMP Trap Messages (DBUpgrader utility)
#### Version 1.2
#### Written by: Premysl Botek (premysl.botek@lab.com)
##################################################################################
#### Note to future developers: when updating the version number of this script, please check/adjust version number setting in database it generates (look for 'THIS_DATABASE_VERSION' keyword) and also update compatibility info setting in database it generates ('COMPATIBILITY_INFO' keyword) - both in sub getDatabaseUpgradeStatement()
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



		fnUpgradeDatabase();


## end - main execution block

##  program exit point	###########################################################################

## service functions


sub fnUpgradeDatabase {

	if (!( -f $databaseFileName )) {
		logEvent( 2,
"File $databaseFileName doesn't exist"
		);
		exit 1;
	}

	eval {

		$dbh = DBI->connect(
			"dbi:SQLite:dbname=$databaseFileName",
			"", "", { RaiseError => 1, sqlite_allow_multiple_statements => 1, }
			, # important to be able to run multiple statements within one Do() run
		);

		my $ss1 = getDatabaseUpgradeStatement();
		$dbh->do($ss1);

		$dbh->disconnect();

		logEvent( 1, "Successfully upgraded $databaseFileName" );

	};
	if ($@) {
		logEvent( 2, "Database error ($databaseFileName): $DBI::errstr" );
		exit 1;
	}

}


sub getDatabaseUpgradeStatement {
	my $result1 = <<DELIMITER1;


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





DELIMITER1

	return $result1;

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
