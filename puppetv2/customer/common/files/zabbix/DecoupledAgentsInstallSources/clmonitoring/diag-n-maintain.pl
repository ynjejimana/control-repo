#!/usr/bin/perl
#### Monitoring Commvault Backup Logs
#### Version 2.3
#### Writen by: Premysl Botek (pbotek@harbourmsp.com)
#### Note to future developers: when updating the version number of this script, please check/adjust version number setting in database it generates (look for 'THIS_DATABASE_VERSION' keyword) and also update compatibility info setting in database it generates ('COMPATIBILITY_INFO' keyword) - both in sub getNewDatabaseCreationStatement()
##################################################################################

## pragmas, global variable declarations, environment setup

use v5.10;
use strict;
use Config::Simple;
use Data::Dumper;
use Net::OpenSSH;
use Time::Piece;
use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);
use DBI;
use File::Path;

our $datadir              = "/clmdata";
our $slowDatabaseFileName = "$datadir/database/clmonitoringdata_slow.db";
our $fastDatabaseFileName = "$datadir/database/clmonitoringdata_fast.db";
our $logfilename          = "$datadir/scriptslog/log.txt";
our $logfilesretention    = "$datadir/reportsretention";

my $loggingLevel = 2
  ; # 0 - no logging, 1 - log errors only, 2 - log everything (errors, warnings, debug info)
my $logOutput = 3
  ; # 1 - output to console, 2 - output to log file, 3 - output to both console and log file

my $thisModuleID =
  "DIAG-N-MAINTAIN";    # just for log file record identification purposes

my $invalidCommandLine = 0;

# AppModes:
# 1 - UNUSED (report-detail-directorylevel)
# 2 - maintain-compactdatabase
# 3 - diag-checkdatabaseintegrity
# 4 - maintain-createnewdatabase
# 5 - UNUSED (Report-Detail-FileLevel)
# 6 - setting-get
# 7 - setting-dumpall
# 8 - report-listall
# 9 - diexception-listall
# 10 - diexception-add
# 11 - dietemplate-listall
# 12 - diexception-remove
# 13 - dietemplate-add
# 14 - client-listall
# 15 - client-listdietemplateassignments
# 16 - client-add
# 17 - dietemplate-assign
# 18 - CLIENT-LISTCEETEMPLATEASSIGNMENTS
# 19 - CEETEMPLATE-LISTALL
# 20 - CEETEMPLATE-ADD
# 21 - CEETEMPLATE-ASSIGN
# 22 - CEEXCEPTION-LISTALL
# 23 - CEEXCEPTION-ADD
# 24 - CEEXCEPTION-REMOVE
# 25 - setting-set
# 26 - CEETEMPLATE-LISTCLIENTASSIGNMENTS
# 27 - DIETEMPLATE-LISTCLIENTASSIGNMENTS
# 28 - DIETEMPLATE UNASSIGN
# 29 - CEETEMPLATE UNASSIGN
# 30 - CEETEMPLATE REMOVE
# 31 - DIETEMPLATE REMOVE
my $appMode = 0;
my $slowDBH;
my $fastDBH;
my $currentReportId;
my $currentClientId;
my $currentDIEtemplateMatchingId;
my $currentClientName;
my $currentDirectoryId;
my $currentDIExceptionId;
my $currentDIExceptionPath;
my $currentDIEtemplateId;
my $currentDIEtemplateName;
my $currentCEExceptionId;
my $currentCEExceptionErrorCode;
my $currentCEEtemplateId;
my $currentCEEtemplateName;
my $currentCEEtemplateMatchingId;

## program entry point
## program initialization

if ( $#ARGV < 1 ) {
	$invalidCommandLine = 1;
}
else {

	$invalidCommandLine = 1;

	if ( uc( $ARGV[0] ) eq "CLIENT" ) {
		if ( uc( $ARGV[1] ) eq "LISTALL" ) {
			$appMode            = 14;
			$invalidCommandLine = 0;

		}

		if ( uc( $ARGV[1] ) eq "ADD" ) {

			$currentClientName = $ARGV[2];

			if ( $currentClientName ne "" ) {
				$appMode            = 16;
				$invalidCommandLine = 0;
			}

		}

		if ( uc( $ARGV[1] ) eq "LISTDIETEMPLATEASSIGNMENTS" ) {

			if ( isInteger( $ARGV[2] ) ) {

				$currentClientId    = $ARGV[2];
				$appMode            = 15;
				$invalidCommandLine = 0;

			}

		}

		if ( uc( $ARGV[1] ) eq "LISTCEETEMPLATEASSIGNMENTS" ) {

			if ( isInteger( $ARGV[2] ) ) {

				$currentClientId    = $ARGV[2];
				$appMode            = 18;
				$invalidCommandLine = 0;

			}

		}

	}

	if ( uc( $ARGV[0] ) eq "DIETEMPLATE" ) {
		if ( uc( $ARGV[1] ) eq "LISTALL" ) {
			$appMode            = 11;
			$invalidCommandLine = 0;

		}

		if ( uc( $ARGV[1] ) eq "ADD" ) {

			$currentDIEtemplateName = $ARGV[2];

			if ( $currentDIEtemplateName ne "" ) {
				$appMode            = 13;
				$invalidCommandLine = 0;
			}

		}

		if ( ( uc( $ARGV[1] ) eq "ASSIGN" ) ) {

			if ( ( isInteger( $ARGV[2] ) ) && ( isInteger( $ARGV[3] ) ) ) {

				$currentDIEtemplateId = $ARGV[2];
				$currentClientId      = $ARGV[3];
				$appMode              = 17;
				$invalidCommandLine   = 0;

			}

		}

		if ( ( uc( $ARGV[1] ) eq "UNASSIGN" ) ) {

			if ( ( isInteger( $ARGV[2] ) ) && ( isInteger( $ARGV[3] ) ) ) {

				$currentDIEtemplateId = $ARGV[2];
				$currentClientId      = $ARGV[3];
				$appMode              = 28;
				$invalidCommandLine   = 0;

			}

		}

		if ( ( uc( $ARGV[1] ) eq "REMOVE" ) ) {

			if ( isInteger( $ARGV[2] ) ) {

				$currentDIEtemplateId = $ARGV[2];
				$appMode              = 31;
				$invalidCommandLine   = 0;

			}

		}

		if ( uc( $ARGV[1] ) eq "LISTCLIENTASSIGNMENTS" ) {

			if ( isInteger( $ARGV[2] ) ) {

				$currentDIEtemplateId = $ARGV[2];
				$appMode              = 27;
				$invalidCommandLine   = 0;

			}
		}

	}

	if ( uc( $ARGV[0] ) eq "CEETEMPLATE" ) {
		if ( uc( $ARGV[1] ) eq "LISTALL" ) {
			$appMode            = 19;
			$invalidCommandLine = 0;

		}

		if ( uc( $ARGV[1] ) eq "ADD" ) {

			$currentCEEtemplateName = $ARGV[2];

			if ( $currentCEEtemplateName ne "" ) {
				$appMode            = 20;
				$invalidCommandLine = 0;
			}

		}

		if ( ( uc( $ARGV[1] ) eq "ASSIGN" ) ) {

			if ( ( isInteger( $ARGV[2] ) ) && ( isInteger( $ARGV[3] ) ) ) {

				$currentCEEtemplateId = $ARGV[2];
				$currentClientId      = $ARGV[3];
				$appMode              = 21;
				$invalidCommandLine   = 0;

			}

		}

		if ( ( uc( $ARGV[1] ) eq "UNASSIGN" ) ) {

			if ( ( isInteger( $ARGV[2] ) ) && ( isInteger( $ARGV[3] ) ) ) {

				$currentCEEtemplateId = $ARGV[2];
				$currentClientId      = $ARGV[3];
				$appMode              = 29;
				$invalidCommandLine   = 0;

			}

		}

		if ( ( uc( $ARGV[1] ) eq "REMOVE" ) ) {

			if ( isInteger( $ARGV[2] ) ) {

				$currentCEEtemplateId = $ARGV[2];
				$appMode              = 30;
				$invalidCommandLine   = 0;

			}

		}

		if ( uc( $ARGV[1] ) eq "LISTCLIENTASSIGNMENTS" ) {

			if ( isInteger( $ARGV[2] ) ) {

				$currentCEEtemplateId = $ARGV[2];
				$appMode              = 26;
				$invalidCommandLine   = 0;

			}
		}

	}

	if ( uc( $ARGV[0] ) eq "DIEXCEPTION" ) {

		if ( uc( $ARGV[1] ) eq "LISTALL" ) {

			if ( isInteger( $ARGV[2] ) ) {

				$currentDIEtemplateId = $ARGV[2];
				$appMode              = 9;
				$invalidCommandLine   = 0;
			}

		}

		if ( uc( $ARGV[1] ) eq "ADD" ) {

			if ( ( isInteger( $ARGV[2] ) ) && ( $ARGV[3] ne "" ) ) {

				$currentDIEtemplateId   = $ARGV[2];
				$currentDIExceptionPath = $ARGV[3];

				$appMode            = 10;
				$invalidCommandLine = 0;

			}

		}

		if ( ( uc( $ARGV[1] ) eq "REMOVE" ) && ( defined $ARGV[2] ) ) {

			if ( isInteger( $ARGV[2] ) ) {

				$currentDIExceptionId = $ARGV[2];

				$appMode            = 12;
				$invalidCommandLine = 0;

			}

		}

	}

	if ( uc( $ARGV[0] ) eq "CEEXCEPTION" ) {

		if ( uc( $ARGV[1] ) eq "LISTALL" ) {

			if ( isInteger( $ARGV[2] ) ) {

				$currentCEEtemplateId = $ARGV[2];
				$appMode              = 22;
				$invalidCommandLine   = 0;
			}

		}

		if ( uc( $ARGV[1] ) eq "ADD" ) {

			if ( ( isInteger( $ARGV[2] ) ) && ( $ARGV[3] ne "" ) ) {

				$currentCEEtemplateId        = $ARGV[2];
				$currentCEExceptionErrorCode = $ARGV[3];

				$appMode            = 23;
				$invalidCommandLine = 0;

			}

		}

		if ( ( uc( $ARGV[1] ) eq "REMOVE" ) && ( defined $ARGV[2] ) ) {

			if ( isInteger( $ARGV[2] ) ) {

				$currentCEExceptionId = $ARGV[2];

				$appMode            = 24;
				$invalidCommandLine = 0;

			}

		}

	}

#	if ( uc( $ARGV[0] ) eq "REPORT" ) {
#
#		if ( uc( $ARGV[1] ) eq "LISTALL" ) {
#			$appMode            = 8;
#			$invalidCommandLine = 0;
#
#		}
#
#		if ( uc( $ARGV[1] ) eq "DETAIL" ) {
#
#			if ( uc( $ARGV[2] ) eq "DIRECTORYLEVEL" ) {
#
#				$appMode         = 1;
#				$currentReportId = $ARGV[3];
#				if ( $currentReportId > 0 ) {
#					$invalidCommandLine = 0;
#				}
#
#			}
#
#			if ( uc( $ARGV[2] ) eq "FILELEVEL" ) {
#
#				( $currentReportId, $currentClientId, $currentDirectoryId ) =
#				  split( /-/, $ARGV[3] )
#				  ; # we parse a nice simplified directory id format - for the user's convenience
#
#				#				$currentReportId    = $ARGV[3];
#				#				$currentClientId    = $ARGV[4];
#				#				$currentDirectoryId = $ARGV[5];
#				#
#
#				if (   ( $currentReportId > 0 )
#					&& ( $currentClientId > 0 )
#					&& ( $currentDirectoryId > 0 ) )
#				{
#					$appMode            = 5;
#					$invalidCommandLine = 0;
#				}
#
#			}
#
#		}
#
#	}

	if ( uc( $ARGV[0] ) eq "SETTING" ) {

		if ( uc( $ARGV[1] ) eq "GET" ) {
			$appMode            = 6;
			$invalidCommandLine = 0;

		}

		if ( uc( $ARGV[1] ) eq "DUMPALL" ) {
			$appMode            = 7;
			$invalidCommandLine = 0;

		}

		if ( ( uc( $ARGV[1] ) eq "SET" ) && ( defined( $ARGV[2] ) ) ) {
			$appMode            = 25;
			$invalidCommandLine = 0;

		}

	}

	if ( uc( $ARGV[0] ) eq "DIAG" ) {

		if ( uc( $ARGV[1] ) eq "CHECKDATABASEINTEGRITY" ) {
			$appMode            = 3;
			$invalidCommandLine = 0;

		}

		if ( uc( $ARGV[1] ) eq "LISTREGISTEREDSTATS" ) {
			$appMode            = 5;
			$invalidCommandLine = 0;

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
	
USAGE:	perl diag-n-maintain.pl <DIAG|MAINTAIN|SETTING|CLIENT|DIEXCEPTION|DIETEMPLATE|CEEXCEPTION|CEETEMPLATE>


CLIENT LISTALL					- Lists all clients registered in the system (their clientIds, names etc.) 

CLIENT ADD <name>				- Adds client to the system (name must be unique and can not contain spaces). Clients are also added to the system automatically during the backup log import process that retrieves all available client names.

CLIENT LISTDIETEMPLATEASSIGNMENTS <clientId>	- Lists all "directory/item" exception templates assigned to the specified client

CLIENT LISTCEETEMPLATEASSIGNMENTS <clientId>	- Lists all client error exception templates assigned to the specified client


DIETEMPLATE LISTALL				- Lists all "directory/item" exception templates registered in the system (their dietemplateIds, names etc.)

DIETEMPLATE ADD <name>				- Adds "directory/item" exception template to the system (name must be unique and can not contain spaces)

DIETEMPLATE REMOVE <dietemplateId>			- Removes specified "directory/item" exception template from the system + its client assignments and exceptions it contains (dietemplateId can be retrieved by DIETEMPLATE LISTALL)

DIETEMPLATE ASSIGN <dietemplateId> <clientId>	- Associates specified "directory/item" exception template with the specified client (dietemplateId can be retrieved by DIETEMPLATE LISTALL, clientId can be retrieved by CLIENT LISTALL)

DIETEMPLATE UNASSIGN <dietemplateId> <clientId>	- Removes association between specified "directory/item" exception template and specified client (dietemplateId can be retrieved by DIETEMPLATE LISTALL, clientId can be retrieved by CLIENT LISTALL)

DIETEMPLATE LISTCLIENTASSIGNMENTS <dietemplateId>	- Lists all clients assigned to the specified "directory/item" exception template


DIEXCEPTION LISTALL <dietemplateId>			- Lists all "directory/item" exceptions from specified "directory/item" exception template (dietemplateId can be retrieved by running DIETEMPLATE LISTALL)

DIEXCEPTION ADD <dietemplateId> <"diexception_path">	- Adds "directory/item" exception to a specified "directory/item" exception template. DIException_path is recursive. (dietemplateId can be retrieved by DIETEMPLATE LISTALL). NOTE: diexception_path must be surrounded by double-quotes or the path may not be interpretted correctly (specially Windows path) 

DIEXCEPTION REMOVE <diexceptionId>			- removes specified "directory/item" exception from its template (diexceptionId can be retrieved by DIEXCEPTION LISTALL) 


CEETEMPLATE LISTALL				- Lists all client error exception templates registered in the system (their ceetemplateIds, names etc.)

CEETEMPLATE ADD <name>				- Adds client error exception template to the system (name must be unique and can not contain spaces)

CEETEMPLATE REMOVE <ceetemplateId>			- Removes specified client error exception template from the system + its client assignments and exceptions it contains (ceetemplateId can be retrieved by CEETEMPLATE LISTALL)

CEETEMPLATE ASSIGN <ceetemplateId> <clientId>	- Associates specified client error exception template with the specified client (ceetemplateId can be retrieved by CEETEMPLATE LISTALL, clientId can be retrieved by CLIENT LISTALL)

CEETEMPLATE UNASSIGN <ceetemplateId> <clientId>	- Removes association between specified client error exception template and specified client (ceetemplateId can be retrieved by CEETEMPLATE LISTALL, clientId can be retrieved by CLIENT LISTALL)

CEETEMPLATE LISTCLIENTASSIGNMENTS <ceetemplateId>	- Lists all clients assigned to the specified client error exception template


CEEXCEPTION LISTALL <ceetemplateId>			- Lists all client error exceptions from specified client error exception template (ceetemplateId can be retrieved by running CEETEMPLATE LISTALL)

CEEXCEPTION ADD <ceetemplateId> <"ceexception_path">	- Adds client error exception to a specified client error exception template. (ceetemplateId can be retrieved by CEETEMPLATE LISTALL)

CEEXCEPTION REMOVE <ceexceptionId>			- removes specified client error exception from its template (ceexceptionId can be retrieved by CEEXCEPTION LISTALL) 


DIAG CHECKDATABASEINTEGRITY			- Checks integrity of clmonitoringdata.db. Shall any integrity problems be detected, it is generally advised to generate a new clean database instead of trying to repairing it by compacting, editing in hex editor, etc.


MAINTAIN COMPACTDATABASE			- Compacts clmonitoringdata.db. Cleans its unused space, repairs and defrags it. No need to do this regularly, the database file will not grow infinitely (old monitored items are deleted from retention and their space recycled) 

MAINTAIN CREATENEWDATABASE			- Creates fresh clmonitoringdata.db with the default schema and fills it by default data (SQL statement is stored inside this script)


SETTING <GET> <setting_name>			- Retrieves the value of specified setting from TA_SETTINGS table 

SETTING <SET> <setting_name> <"value">			- Sets the value of specified setting in TA_SETTINGS table 

SETTING DUMPALL					- Dumps all settings from TA_SETTINGS table + their descriptions

	
NOTE 1:		Command line parameters are case insensitive (script written by an ex Windows guy)	
	
USAGELABEL

	exit 0;
}

## main execution block

given ($appMode) {

	when (1) {

		#fnReportDetailDirectoryLevel();
	}

	when (2) {
		fnMaintainCompactDatabase();
	}

	when (3) {
		fnDiagCheckDatabaseIntegrity();
	}

	when (4) {
		fnMaintainCreateNewDatabase();
	}

	when (5) {

		#fnReportDetailFileLevel();
	}

	when (6) {
		fnSettingGet();
	}

	when (7) {
		fnSettingDumpAll();
	}

	when (8) {

		#fnReportListAll();
	}

	when (9) {
		fnDIExceptionListAll();
	}

	when (10) {
		fnDIExceptionAdd();
	}

	when (11) {
		fnDIEtemplateListAll();
	}

	when (12) {
		fnDIExceptionRemove();
	}

	when (13) {
		fnDIEtemplateAdd();
	}

	when (14) {
		fnClientListAll();
	}

	when (15) {
		fnClientListDIEtemplateAssignments();
	}

	when (16) {
		fnClientAdd();
	}

	when (17) {
		fnDIEtemplateAssign();
	}

	when (18) {
		fnClientListCEEtemplateAssignments();
	}

	when (19) {
		fnCEEtemplateListAll();
	}

	when (20) {
		fnCEEtemplateAdd();
	}

	when (21) {
		fnCEEtemplateAssign();
	}

	when (22) {
		fnCEExceptionListAll();
	}

	when (23) {
		fnCEExceptionAdd();
	}

	when (24) {
		fnCEExceptionRemove();
	}

	when (25) {
		fnSettingSet();
	}

	when (26) {
		fnCEEtemplateListClientAssignments();
	}

	when (27) {
		fnDIEtemplateListClientAssignments();
	}

	when (28) {
		fnDIEtemplateUnAssign();
	}

	when (29) {
		fnCEEtemplateUnAssign();
	}

	when (30) {
		fnCEEtemplateRemove();
	}

	when (31) {
		fnDIEtemplateRemove();
	}

}

## end - main execution block

##  program exit point	###########################################################################

sub fnDiagCheckDatabaseIntegrity {

	logEvent( 1,
		"Running integrity check on $slowDatabaseFileName, please wait..." );
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
		my $sth = $slowDBH->prepare("pragma integrity_check");

		$sth->execute();

		my @rowArray;
		while ( @rowArray = $sth->fetchrow_array() ) {

			print "results : @rowArray[0]\n";

		}

		$sth->finish();   # end statement, release resources (not a transaction)

		$slowDBH->disconnect();

		logEvent( 1, "Integrity check finished." );

	};

	if ($@) {
		logEvent( 2, "Database error: $DBI::errstr" );
		exit 1;
	}

}

sub fnMaintainCreateNewDatabase {
my $fastDBHTmp;	

	if ( -f $slowDatabaseFileName ) {
		logEvent( 2,
"Unable to create new database set. File $slowDatabaseFileName already exists"
		);
		exit 1;
	}

	if ( -f $fastDatabaseFileName ) {
		logEvent( 2,
"Unable to create new database set. File $fastDatabaseFileName already exists"
		);
		exit 1;
	}

## create slow database

	eval {

		$slowDBH = DBI->connect(
			"dbi:SQLite:dbname=$slowDatabaseFileName",
			"", "",
			{ RaiseError => 1, sqlite_allow_multiple_statements => 1, }
			, # important to be able to run multiple statements within one Do() run
		);

		my $ss1 = getNewSlowDatabaseCreationStatement();
		$slowDBH->do($ss1);

		$slowDBH->disconnect();

		logEvent( 1, "Successfully created $slowDatabaseFileName" );

	};
	if ($@) {
		logEvent( 2, "Database error ($slowDatabaseFileName): $DBI::errstr" );
		exit 1;
	}

## create fast database

	eval {

		$fastDBHTmp = DBI->connect(
			"dbi:SQLite:dbname=$fastDatabaseFileName",
			"", "",
			{ RaiseError => 1, sqlite_allow_multiple_statements => 1, }
			, # important to be able to run multiple statements within one Do() run
		);

		my $ss1 = getNewFastDatabaseCreationStatement();
		$fastDBHTmp->do($ss1);

		$fastDBHTmp->disconnect();

		logEvent( 1, "Successfully created $fastDatabaseFileName" );

	};
	if ($@) {
		logEvent( 2, "Database error ($fastDatabaseFileName): $DBI::errstr" );
		exit 1;
	}

	my $question =
"Do you also want to empty $logfilesretention to stay in sync with the database indexing (reports will start again from reportId 1) ? ";

	if ( askQuestionYN( $question, 1 ) ) {

		logEvent( 1, "Deleting Report Retention: $logfilesretention" );

		rmtree( $logfilesretention, { keep_root => 1 } );

	}

}

sub fnMaintainCompactDatabase {

	logEvent( 1, "Compacting $slowDatabaseFileName, please wait..." );

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

		$slowDBH->do('VACUUM');
		$slowDBH->disconnect();
		logEvent( 1, "Compacting successfully completed." );

	};

	if ($@) {
		logEvent( 2, "Database error: $DBI::errstr" );
		exit 1;
	}

}

sub fnSettingSet {
	my $settingName;
	my $settingValue;

	eval {

		# connect to database

		if ( !-f $fastDatabaseFileName ) {
			logEvent( 2, "Database file $fastDatabaseFileName does not exist" );
			exit 1;
		}

		$fastDBH = DBI->connect(
			"dbi:SQLite:dbname=$fastDatabaseFileName",
			"", "", { RaiseError => 1 },
		);

		$settingName  = $ARGV[2];
		$settingValue = $ARGV[3];

		if ( writeSettingToDatabase1( $settingName, $settingValue ) ) {

			logEvent( 1, "Successfully set $settingName = \"$settingValue\"" );

		}

		$fastDBH->disconnect();

	};
	if ($@) {
		logEvent( 2, "Database error: $DBI::errstr" );
		exit 1;
	}
}

sub fnSettingGet {

	my $settingValue;

	eval {

		# connect to database

		if ( !-f $fastDatabaseFileName ) {
			logEvent( 2, "Database file $fastDatabaseFileName does not exist" );
			exit 1;
		}

		$fastDBH = DBI->connect(
			"dbi:SQLite:dbname=$fastDatabaseFileName",
			"", "", { RaiseError => 1 },
		);

		readSettingFromDatabase1( $ARGV[2], \$settingValue ) or exit 1;

		if ( !defined($settingValue) ) {
			logEvent( 2, "$ARGV[2] does not exist in TA_SETTINGS" );

		}
		else {
			print "$ARGV[2] = \"$settingValue\"\n";

		}

		$fastDBH->disconnect();

	};
	if ($@) {
		logEvent( 2, "Database error: $DBI::errstr" );
		exit 1;
	}

}

sub fnSettingDumpAll {

	eval {

		# connect to database

		if ( !-f $fastDatabaseFileName ) {
			logEvent( 2, "Database file $fastDatabaseFileName does not exist" );
			exit 1;
		}

		$fastDBH = DBI->connect(
			"dbi:SQLite:dbname=$fastDatabaseFileName",
			"", "", { RaiseError => 1 },
		);

		my $sql1 =
"SELECT DS_KEY,DS_VALUE,DS_DESCRIPTION FROM TA_SETTINGS ORDER BY DS_KEY,DS_VALUE";

		my $sth = $fastDBH->prepare($sql1);

		$sth->execute();

		my @rowArray;
		my $rowCounter = 0;

		while ( @rowArray = $sth->fetchrow_array() ) {

			my $strDescription = "";
			if ( !( @rowArray[2] eq "" ) ) {
				$strDescription = "[@rowArray[2]]";
			}

			print "@rowArray[0] = \"@rowArray[1]\" $strDescription\n\n";

			$rowCounter++;

		}

		$sth->finish();   # end statement, release resources (not a transaction)
		$fastDBH->disconnect();
		print("Listed $rowCounter settings.\n");

	};

	if ($@) {
		logEvent( 2, "Database error: $DBI::errstr" );
		exit 1;
	}

}

#
#sub fnReportDetailFileLevel {
#
#	eval {
#
#		# connect to database
#
#		if ( !-f $slowDatabaseFileName ) {
#			logEvent( 2, "Database file $slowDatabaseFileName does not exist" );
#			exit 1;
#		}
#
#		$slowDBH = DBI->connect(
#			"dbi:SQLite:dbname=$slowDatabaseFileName",
#			"", "", { RaiseError => 1 },
#		);
#
#		my $sql1 = <<DELIMITER1;
#
# SELECT A.DL_ITEM_PATH_ID,
#       E.DS_DATA,
#       J.DS_DATA,
#       K.DS_DATA,
#       G.DS_NAME AS CLIENTNAME,
#       H.DS_NAME AS SUBCLIENTNAME,
#       I.DS_NAME AS STORAGEPOLICYNAME,
#       G.DL_ID,
#       H.DL_ID,
#       I.DL_ID
#  FROM TA_JOB_ITEMS A,
#       TA_REDUNDANT_DATA_LOOKUP E,
#       TA_JOBS F,
#       TA_CLIENTS G,
#       TA_SUBCLIENTS H,
#       TA_STORAGE_POLICIES I,
#       TA_REDUNDANT_DATA_LOOKUP J,
#       TA_REDUNDANT_DATA_LOOKUP K
# WHERE ( F.DL_REPORT_ID = ?
#           AND
#           F.DL_CLIENT_ID = ?
#           AND
#           A.DL_ITEM_PATH_ID = ?
#           AND
#           A.DL_JOB_ID = F.DL_ID
#           AND
#           A.DL_ITEM_PATH_ID = E.DL_ID
#           AND
#           F.DL_CLIENT_ID = G.DL_ID
#           AND
#           F.DL_SUBCLIENT_ID = H.DL_ID
#           AND
#           F.DL_STORAGE_POLICY_ID = I.DL_ID
#           AND
#           A.DL_ITEM_NAME_ID = J.DL_ID
#           AND
#           A.DL_ITEM_REASON_ID = K.DL_ID
#           AND
#          NOT EXISTS (
#                        SELECT 1
#                          FROM TA_DIEXCEPTIONS B,
#                               TA_DIEXCEPTION_TEMPLATES_MATCHING C,
#                               TA_REDUNDANT_DATA_LOOKUP D
#                         WHERE B.DL_EXCEPTION_TEMPLATE_ID = C.DL_EXCEPTION_TEMPLATE_ID
#                               AND
#                               F.DL_CLIENT_ID = C.DL_CLIENT_ID
#                               AND
#                               A.DL_ITEM_PATH_ID = D.DL_ID
#                               AND
#                               INSTR( D.DS_DATA, B.DS_ITEM_PATH ) = 1
#                    )
#        )
# ORDER BY A.DL_ID;
#
#DELIMITER1
#
#		my $sth = $slowDBH->prepare($sql1);
#
#		$sth->execute( $currentReportId, $currentClientId,
#			$currentDirectoryId );
#
#		my @rowArray;
#		my $rowCounter = 1;
#
#		while ( @rowArray = $sth->fetchrow_array() ) {
#
#			if ( $rowCounter == 1 ) {
#
#				my $compoundDirectoryId =
#				  "$currentReportId-@rowArray[7]-@rowArray[0]";
#
#				my $currentNavigationString =
#"\nStoragePolicyId @rowArray[9] : @rowArray[6]\n SubclientId @rowArray[8] : @rowArray[5]\n  ClientId @rowArray[7] : @rowArray[4]\n   DirectoryId $compoundDirectoryId : \"@rowArray[1]\"\n";
#
#				print $currentNavigationString;
#			}
#
#			print "     \"@rowArray[2]\" : @rowArray[3]\n";
#
#			$rowCounter++;
#
#		}
#
#		$sth->finish();   # end statement, release resources (not a transaction)
#		$slowDBH->disconnect();
#
#		$rowCounter--;
#		print("\nListed $rowCounter problematic files.\n");
#
#	};
#
#	if ($@) {
#		logEvent( 2, "Database error: $DBI::errstr" );
#		exit 1;
#	}
#
#}
#
#sub fnReportDetailDirectoryLevel {
#
#	eval {
#
#		# connect to database
#
#		if ( !-f $slowDatabaseFileName ) {
#			logEvent( 2, "Database file $slowDatabaseFileName does not exist" );
#			exit 1;
#		}
#
#		$slowDBH = DBI->connect(
#			"dbi:SQLite:dbname=$slowDatabaseFileName",
#			"", "", { RaiseError => 1 },
#		);
#
#		my $sql1 = <<DELIMITER1;
#
#SELECT DISTINCT ( A.DL_ITEM_PATH_ID ),
#                E.DS_DATA,
#                G.DS_NAME AS CLIENTNAME,
#                H.DS_NAME AS SUBCLIENTNAME,
#                I.DS_NAME AS STORAGEPOLICYNAME,
#                G.DL_ID,
#                H.DL_ID,
#                I.DL_ID
#           FROM TA_JOB_ITEMS A,
#                TA_REDUNDANT_DATA_LOOKUP E,
#                TA_JOBS F,
#                TA_CLIENTS G,
#                TA_SUBCLIENTS H,
#                TA_STORAGE_POLICIES I
#          WHERE ( F.DL_REPORT_ID = ?
#                    AND
#                    A.DL_JOB_ID = F.DL_ID
#                    AND
#                    A.DL_ITEM_PATH_ID = E.DL_ID
#                    AND
#                    F.DL_CLIENT_ID = G.DL_ID
#                    AND
#                    F.DL_SUBCLIENT_ID = H.DL_ID
#                    AND
#                    F.DL_STORAGE_POLICY_ID = I.DL_ID
#                    AND
#                    NOT EXISTS (
#                        SELECT 1
#                          FROM TA_DIEXCEPTIONS B,
#                               TA_DIEXCEPTION_TEMPLATES_MATCHING C,
#                               TA_REDUNDANT_DATA_LOOKUP D
#                         WHERE B.DL_EXCEPTION_TEMPLATE_ID = C.DL_EXCEPTION_TEMPLATE_ID
#                               AND
#                               F.DL_CLIENT_ID = C.DL_CLIENT_ID
#                               AND
#                               A.DL_ITEM_PATH_ID = D.DL_ID
#                               AND
#                               INSTR( D.DS_DATA, B.DS_ITEM_PATH ) = 1
#                    )
#                 )
#          ORDER BY I.DS_NAME,
#                    H.DS_NAME,
#                    G.DS_NAME,
#                    A.DL_ID;
#
#
#DELIMITER1
#
#		my $sth = $slowDBH->prepare($sql1);
#
#		$sth->execute($currentReportId);
#
#		my @rowArray;
#		my $rowCounter = 1;
#		my $currentNavigationString;
#		my $lastNavigationString;
#
#		while ( @rowArray = $sth->fetchrow_array() ) {
#
#			#			my $itemProblemCount;
#			#			my $itemDirectoriesProblemCount;
#			#
#			#			my $ignoredItemProblemCount;
#			#			my $ignoredItemDirectoriesProblemCount;
#			#
#			#			my $error = evaluateReportProblems1(
#			#				@rowArray[2],
#			#				\$itemProblemCount,
#			#				\$itemDirectoriesProblemCount,
#			#				\$ignoredItemProblemCount,
#			#				\$ignoredItemDirectoriesProblemCount
#			#			);
#
#			$currentNavigationString =
#"\nStoragePolicyId @rowArray[7] : @rowArray[4]\n SubclientId @rowArray[6] : @rowArray[3]\n  ClientId @rowArray[5] : @rowArray[2]\n";
#			if ( $currentNavigationString ne $lastNavigationString ) {
#				print $currentNavigationString;
#			}
#
#			my $compoundDirectoryId =
#			  "$currentReportId-@rowArray[5]-@rowArray[0]";
#
#			print "   DirectoryId $compoundDirectoryId : \"@rowArray[1]\"\n";
#
#			$rowCounter++;
#			$lastNavigationString = $currentNavigationString;
#
#		}
#
#		$sth->finish();   # end statement, release resources (not a transaction)
#		$slowDBH->disconnect();
#
#		$rowCounter--;
#		print("\nListed $rowCounter problematic directories.\n");
#
#	};
#
#	if ($@) {
#		logEvent( 2, "Database error: $DBI::errstr" );
#		exit 1;
#	}
#
#}

#sub fnReportListAll {
#
#	my $elapsedTime;
#
#	eval {
#
#		# connect to database
#
#		if ( !-f $slowDatabaseFileName ) {
#			logEvent( 2, "Database file $slowDatabaseFileName does not exist" );
#			exit 1;
#		}
#
#		$slowDBH = DBI->connect(
#			"dbi:SQLite:dbname=$slowDatabaseFileName",
#			"", "", { RaiseError => 1 },
#		);
#
#		my $sth =
#		  $slowDBH->prepare(
#"SELECT DS_FILENAME,DT_IMPORT_STARTED,DL_ID,DT_IMPORT_FINISHED,(strftime('%s',DT_IMPORT_FINISHED) - strftime('%s',DT_IMPORT_STARTED)) as ELAPSED_TIME FROM TA_REPORTS ORDER BY DL_ID"
#		  );
#
#		$sth->execute();
#
#		my @rowArray;
#		my $rowCounter = 1;
#
#		while ( @rowArray = $sth->fetchrow_array() ) {
#
#			my $itemProblemCount;
#			my $itemDirectoriesProblemCount;
#
#			my $ignoredItemProblemCount;
#			my $ignoredItemDirectoriesProblemCount;
#
#			my $error = evaluateReportProblems1(
#				@rowArray[2],
#				\$itemProblemCount,
#				\$itemDirectoriesProblemCount,
#				\$ignoredItemProblemCount,
#				\$ignoredItemDirectoriesProblemCount
#			);
#
#			my $importJobStatus        = "";
#			my $importJobCompletedInfo = "";
#
#			if ( !defined( @rowArray[3] ) ) {
#				$importJobStatus = "import in progress, ";
#			}
#			else {
#
#				$elapsedTime = @rowArray[4];
#				if ( $elapsedTime > 60 ) {
#					$elapsedTime =
#					  ", imported in " . ( $elapsedTime / 60 ) . " minutes";
#				}
#				else {
#					$elapsedTime = ", imported in $elapsedTime seconds";
#				}
#
#				$importJobCompletedInfo = ", completed on @rowArray[3]";
#			}
#
#			print
#"\n* ReportId @rowArray[2] : file \"@rowArray[0]\"$elapsedTime, started on @rowArray[1]$importJobCompletedInfo. Found $itemProblemCount problematic items in $itemDirectoriesProblemCount directories, ignored $ignoredItemProblemCount items in $ignoredItemDirectoriesProblemCount directories.\n";
#
#			$rowCounter++;
#
#		}
#
#		$sth->finish();   # end statement, release resources (not a transaction)
#		$slowDBH->disconnect();
#
#		$rowCounter--;
#		print("\nListed $rowCounter reports.\n");
#
#	};
#
#	if ($@) {
#		logEvent( 2, "\nDatabase error: $DBI::errstr" );
#		exit 1;
#	}
#
#}

sub fnClientListCEEtemplateAssignments {

	# lists client error exception templates assigned to the specified client

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

		my $sql1 = <<DELIMITER1;
		
SELECT C.DL_ID,
       C.DS_NAME,
       A.DL_ID,
       B.DL_ID,
       B.DS_NAME
  FROM TA_CEEXCEPTION_TEMPLATES_MATCHING A, 
       TA_CEEXCEPTION_TEMPLATES B, 
       TA_CLIENTS C
 WHERE A.DL_EXCEPTION_TEMPLATE_ID = B.DL_ID 
       AND
       C.DL_ID = ?;

DELIMITER1

		my $sth = $slowDBH->prepare($sql1);

		$sth->execute($currentClientId);

		my @rowArray;
		my $rowCounter = 1;

		while ( @rowArray = $sth->fetchrow_array() ) {

			if ( $rowCounter == 1 ) {
				print "\nclientId @rowArray[0] [@rowArray[1]] assignments : \n";
				$currentClientName = @rowArray[1];
			}

			print
" assignmentId @rowArray[2] : ceetemplateId @rowArray[3] [@rowArray[4]]\n";

			$rowCounter++;

		}

		$sth->finish();   # end statement, release resources (not a transaction)
		$slowDBH->disconnect();

		$rowCounter--;
		print(
"\nListed $rowCounter exception templates assigned with $currentClientName.\n"
		);

	};

	if ($@) {
		logEvent( 2, "\nDatabase error: $DBI::errstr" );
		exit 1;
	}

}

sub fnClientListDIEtemplateAssignments {

	# lists directory/item exception templates assigned to the specified client

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

		my $sql1 = <<DELIMITER1;
		
SELECT C.DL_ID,
       C.DS_NAME,
       A.DL_ID,
       B.DL_ID,
       B.DS_NAME
  FROM TA_DIEXCEPTION_TEMPLATES_MATCHING A, 
       TA_DIEXCEPTION_TEMPLATES B, 
       TA_CLIENTS C
 WHERE A.DL_EXCEPTION_TEMPLATE_ID = B.DL_ID 
       AND
       C.DL_ID = ?;

DELIMITER1

		my $sth = $slowDBH->prepare($sql1);

		$sth->execute($currentClientId);

		my @rowArray;
		my $rowCounter = 1;

		while ( @rowArray = $sth->fetchrow_array() ) {

			if ( $rowCounter == 1 ) {
				print "\nclientId @rowArray[0] [@rowArray[1]] assignments : \n";
				$currentClientName = @rowArray[1];
			}

			print
" assignmentId @rowArray[2] : dietemplateId @rowArray[3] [@rowArray[4]]\n";

			$rowCounter++;

		}

		$sth->finish();   # end statement, release resources (not a transaction)
		$slowDBH->disconnect();

		$rowCounter--;
		print(
"\nListed $rowCounter directory/item exception templates assigned with $currentClientName.\n"
		);

	};

	if ($@) {
		logEvent( 2, "\nDatabase error: $DBI::errstr" );
		exit 1;
	}

}

sub fnCEEtemplateListClientAssignments() {

	# list all clients associated with specified template

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

		my $sql1 = <<DELIMITER1;

SELECT B.DL_ID,
       B.DS_NAME,
       A.DS_NAME
  FROM TA_CEEXCEPTION_TEMPLATES A, 
       TA_CLIENTS B, 
       TA_CEEXCEPTION_TEMPLATES_MATCHING C
 WHERE C.DL_EXCEPTION_TEMPLATE_ID = A.DL_ID 
       AND
       C.DL_CLIENT_ID = B.DL_ID 
       AND
       A.DL_ID = ?
 ORDER BY B.DL_ID;

DELIMITER1

		my $sth = $slowDBH->prepare($sql1);

		$sth->execute($currentCEEtemplateId);

		my @rowArray;
		my $rowCounter = 1;
		my $templateName;

		while ( @rowArray = $sth->fetchrow_array() ) {

			print "\n* ClientId @rowArray[0] : \"@rowArray[1]\" \n";
			$templateName = @rowArray[2];

			$rowCounter++;

		}

		$sth->finish();   # end statement, release resources (not a transaction)
		$slowDBH->disconnect();

		$rowCounter--;
		print(
"\nListed $rowCounter clients associated with ceetemplateId $currentCEEtemplateId \"$templateName\".\n"
		);

	};

	if ($@) {
		logEvent( 2, "\nDatabase error: $DBI::errstr" );
		exit 1;
	}

}

sub fnDIEtemplateListClientAssignments() {

	# list all clients associated with specified template

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

		my $sql1 = <<DELIMITER1;

SELECT B.DL_ID,
       B.DS_NAME,
       A.DS_NAME
  FROM TA_DIEXCEPTION_TEMPLATES A, 
       TA_CLIENTS B, 
       TA_DIEXCEPTION_TEMPLATES_MATCHING C
 WHERE C.DL_EXCEPTION_TEMPLATE_ID = A.DL_ID 
       AND
       C.DL_CLIENT_ID = B.DL_ID 
       AND
       A.DL_ID = ?
 ORDER BY B.DL_ID;

DELIMITER1

		my $sth = $slowDBH->prepare($sql1);

		$sth->execute($currentDIEtemplateId);

		my @rowArray;
		my $rowCounter = 1;
		my $templateName;

		while ( @rowArray = $sth->fetchrow_array() ) {

			print "\n* ClientId @rowArray[0] : \"@rowArray[1]\" \n";
			$templateName = @rowArray[2];

			$rowCounter++;

		}

		$sth->finish();   # end statement, release resources (not a transaction)
		$slowDBH->disconnect();

		$rowCounter--;
		print(
"\nListed $rowCounter clients associated with dietemplateId $currentDIEtemplateId \"$templateName\".\n"
		);

	};

	if ($@) {
		logEvent( 2, "\nDatabase error: $DBI::errstr" );
		exit 1;
	}

}

sub fnClientListAll {

	# list all clients registered in the system

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

		my $sql1 = <<DELIMITER1;
SELECT DL_ID,DS_NAME
  FROM TA_CLIENTS
  ORDER BY DL_ID
DELIMITER1

		my $sth = $slowDBH->prepare($sql1);

		$sth->execute();

		my @rowArray;
		my $rowCounter = 1;

		while ( @rowArray = $sth->fetchrow_array() ) {

			print "\n* ClientId @rowArray[0] : \"@rowArray[1]\" \n";

			$rowCounter++;

		}

		$sth->finish();   # end statement, release resources (not a transaction)
		$slowDBH->disconnect();

		$rowCounter--;
		print("\nListed $rowCounter clients.\n");

	};

	if ($@) {
		logEvent( 2, "\nDatabase error: $DBI::errstr" );
		exit 1;
	}

}

sub fnCEEtemplateAssign {

# assign specified client error template with a specified client (can assign to more than one client, naturally)

	my $question =
"This will assign template ceetemplateId $currentCEEtemplateId to clientId $currentClientId and affect its client failure exceptions. Proceed?";

	if ( askQuestionYN($question) ) {

		eval {

			# connect to database

			if ( !-f $slowDatabaseFileName ) {
				logEvent( 2,
					"Database file $slowDatabaseFileName does not exist" );
				exit 1;
			}

			$slowDBH = DBI->connect(
				"dbi:SQLite:dbname=$slowDatabaseFileName",
				"", "", { RaiseError => 1 },
			);

			$slowDBH->{PrintError} =
			  0;    # we handle/report exceptions ourselves in here

			# use parametrized query - its safer, cleaner and more convenient
			my $sth =
			  $slowDBH->prepare(
"INSERT INTO TA_CEEXCEPTION_TEMPLATES_MATCHING (DL_EXCEPTION_TEMPLATE_ID,DL_CLIENT_ID) VALUES (?,?)"
			  );
			my $rows_affected =
			  $sth->execute( $currentCEEtemplateId, $currentClientId );
			$sth->finish()
			  ;     # end statement, release resources (not a transaction)

			$currentCEEtemplateMatchingId =
			  getHighestTableID("TA_CEEXCEPTION_TEMPLATES_MATCHING");

			$slowDBH->disconnect();

			print(
"Added $rows_affected rows. AssignmentId is $currentCEEtemplateMatchingId.\n"
			);

		};

		if ($@) {
			logEvent( 2, "Database error: $DBI::errstr" );
			exit 1;
		}

	}
}

sub fnDIEtemplateAssign {

# assign the specified directory/item exception template to the specified client

	my $question =
"This will assign template dietemplateId $currentDIEtemplateId to clientId $currentClientId and affect its directory/item failure exceptions. Proceed?";

	if ( askQuestionYN($question) ) {

		eval {

			# connect to database

			if ( !-f $slowDatabaseFileName ) {
				logEvent( 2,
					"Database file $slowDatabaseFileName does not exist" );
				exit 1;
			}

			$slowDBH = DBI->connect(
				"dbi:SQLite:dbname=$slowDatabaseFileName",
				"", "", { RaiseError => 1 },
			);

			$slowDBH->{PrintError} =
			  0;    # we handle/report exceptions ourselves in here

			# use parametrized query - its safer, cleaner and more convenient
			my $sth =
			  $slowDBH->prepare(
"INSERT INTO TA_DIEXCEPTION_TEMPLATES_MATCHING (DL_EXCEPTION_TEMPLATE_ID,DL_CLIENT_ID) VALUES (?,?)"
			  );
			my $rows_affected =
			  $sth->execute( $currentDIEtemplateId, $currentClientId );
			$sth->finish()
			  ;     # end statement, release resources (not a transaction)

			$currentDIEtemplateMatchingId =
			  getHighestTableID("TA_DIEXCEPTION_TEMPLATES_MATCHING");

			$slowDBH->disconnect();

			print(
"Added $rows_affected rows. AssignmentId is $currentDIEtemplateMatchingId.\n"
			);

		};

		if ($@) {
			logEvent( 2, "Database error: $DBI::errstr" );
			exit 1;
		}

	}

}

sub fnDIEtemplateUnAssign {

# unassign the specified directory/item exception template from the specified client

	my $question =
"This will unassign template dietemplateId $currentDIEtemplateId from clientId $currentClientId and affect its directory/item exceptions. Proceed?";

	if ( askQuestionYN($question) ) {

		eval {

			# connect to database

			if ( !-f $slowDatabaseFileName ) {
				logEvent( 2,
					"Database file $slowDatabaseFileName does not exist" );
				exit 1;
			}

			$slowDBH = DBI->connect(
				"dbi:SQLite:dbname=$slowDatabaseFileName",
				"", "", { RaiseError => 1 },
			);

			$slowDBH->{PrintError} =
			  0;    # we handle/report exceptions ourselves in here

			# use parametrized query - its safer, cleaner and more convenient
			my $sth =
			  $slowDBH->prepare(
"DELETE FROM TA_DIEXCEPTION_TEMPLATES_MATCHING WHERE DL_EXCEPTION_TEMPLATE_ID=? AND DL_CLIENT_ID=?"
			  );
			my $rows_affected =
			  $sth->execute( $currentDIEtemplateId, $currentClientId );
			$sth->finish()
			  ;     # end statement, release resources (not a transaction)

			$slowDBH->disconnect();

			print("Deleted $rows_affected rows.\n");

		};

		if ($@) {
			logEvent( 2, "Database error: $DBI::errstr" );
			exit 1;
		}

	}

}

sub fnCEEtemplateRemove {

 # remove exception template + its client associations + exceptions it contained

	my $question =
"This will delete template with ceetemplateId $currentCEEtemplateId, its client associations and exceptions it contains. Proceed?";

	if ( askQuestionYN($question) ) {

		eval {

			# connect to database

			if ( !-f $slowDatabaseFileName ) {
				logEvent( 2,
					"Database file $slowDatabaseFileName does not exist" );
				exit 1;
			}

			$slowDBH = DBI->connect(
				"dbi:SQLite:dbname=$slowDatabaseFileName",
				"", "", { RaiseError => 1 },
			);

			$slowDBH->{PrintError} =
			  0;    # we handle/report exceptions ourselves in here

			# use parametrized query - its safer, cleaner and more convenient
			my $sth =
			  $slowDBH->prepare(
"DELETE FROM TA_CEEXCEPTION_TEMPLATES_MATCHING WHERE DL_EXCEPTION_TEMPLATE_ID=?"
			  );
			my $rows_affected = $sth->execute($currentCEEtemplateId);
			$sth->finish()
			  ;     # end statement, release resources (not a transaction)

			print(
"Deleted $rows_affected client assignments for ceetemplateId $currentCEEtemplateId.\n"
			);

			# use parametrized query - its safer, cleaner and more convenient
			my $sth =
			  $slowDBH->prepare(
				"DELETE FROM TA_CEEXCEPTIONS WHERE DL_EXCEPTION_TEMPLATE_ID=?");
			my $rows_affected = $sth->execute($currentCEEtemplateId);
			$sth->finish()
			  ;     # end statement, release resources (not a transaction)

			print(
"Deleted $rows_affected exceptions contained by ceetemplateId $currentCEEtemplateId.\n"
			);

			# use parametrized query - its safer, cleaner and more convenient
			my $sth =
			  $slowDBH->prepare(
				"DELETE FROM TA_CEEXCEPTION_TEMPLATES WHERE DL_ID=?");
			my $rows_affected = $sth->execute($currentCEEtemplateId);
			$sth->finish()
			  ;     # end statement, release resources (not a transaction)

			print("Deleted $rows_affected rows.\n");

			$slowDBH->disconnect();

		};

		if ($@) {
			logEvent( 2, "Database error: $DBI::errstr" );
			exit 1;
		}
	}
}

sub fnDIEtemplateRemove {

 # remove exception template + its client associations + exceptions it contained

	my $question =
"This will delete template with dietemplateId $currentDIEtemplateId, its client associations and exceptions it contains. Proceed?";

	if ( askQuestionYN($question) ) {

		eval {

			# connect to database

			if ( !-f $slowDatabaseFileName ) {
				logEvent( 2,
					"Database file $slowDatabaseFileName does not exist" );
				exit 1;
			}

			$slowDBH = DBI->connect(
				"dbi:SQLite:dbname=$slowDatabaseFileName",
				"", "", { RaiseError => 1 },
			);

			$slowDBH->{PrintError} =
			  0;    # we handle/report exceptions ourselves in here

			# use parametrized query - its safer, cleaner and more convenient
			my $sth =
			  $slowDBH->prepare(
"DELETE FROM TA_DIEXCEPTION_TEMPLATES_MATCHING WHERE DL_EXCEPTION_TEMPLATE_ID=?"
			  );
			my $rows_affected = $sth->execute($currentDIEtemplateId);
			$sth->finish()
			  ;     # end statement, release resources (not a transaction)

			print(
"Deleted $rows_affected client assignments for dietemplateId $currentDIEtemplateId.\n"
			);

			# use parametrized query - its safer, cleaner and more convenient
			my $sth =
			  $slowDBH->prepare(
				"DELETE FROM TA_DIEXCEPTIONS WHERE DL_EXCEPTION_TEMPLATE_ID=?");
			my $rows_affected = $sth->execute($currentDIEtemplateId);
			$sth->finish()
			  ;     # end statement, release resources (not a transaction)

			print(
"Deleted $rows_affected exceptions contained by dietemplateId $currentDIEtemplateId.\n"
			);

			# use parametrized query - its safer, cleaner and more convenient
			my $sth =
			  $slowDBH->prepare(
				"DELETE FROM TA_DIEXCEPTION_TEMPLATES WHERE DL_ID=?");
			my $rows_affected = $sth->execute($currentDIEtemplateId);
			$sth->finish()
			  ;     # end statement, release resources (not a transaction)

			print("Deleted $rows_affected rows.\n");

			$slowDBH->disconnect();

		};

		if ($@) {
			logEvent( 2, "Database error: $DBI::errstr" );
			exit 1;
		}
	}
}

sub fnCEEtemplateUnAssign {

# unassign the specified client error exception template from the specified client

	my $question =
"This will unassign template ceetemplateId $currentCEEtemplateId from clientId $currentClientId and affect its client error exceptions. Proceed?";

	if ( askQuestionYN($question) ) {

		eval {

			# connect to database

			if ( !-f $slowDatabaseFileName ) {
				logEvent( 2,
					"Database file $slowDatabaseFileName does not exist" );
				exit 1;
			}

			$slowDBH = DBI->connect(
				"dbi:SQLite:dbname=$slowDatabaseFileName",
				"", "", { RaiseError => 1 },
			);

			$slowDBH->{PrintError} =
			  0;    # we handle/report exceptions ourselves in here

			# use parametrized query - its safer, cleaner and more convenient
			my $sth =
			  $slowDBH->prepare(
"DELETE FROM TA_CEEXCEPTION_TEMPLATES_MATCHING WHERE DL_EXCEPTION_TEMPLATE_ID=? AND DL_CLIENT_ID=?"
			  );
			my $rows_affected =
			  $sth->execute( $currentCEEtemplateId, $currentClientId );
			$sth->finish()
			  ;     # end statement, release resources (not a transaction)

			$slowDBH->disconnect();

			print("Deleted $rows_affected rows.\n");

		};

		if ($@) {
			logEvent( 2, "Database error: $DBI::errstr" );
			exit 1;
		}

	}

}

sub fnDIEtemplateListAll {

	# list all directory/item exception templates that exist in the system

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

		my $sql1 = <<DELIMITER1;
SELECT DL_ID,DS_NAME
  FROM TA_DIEXCEPTION_TEMPLATES
  ORDER BY DL_ID
DELIMITER1

		my $sth = $slowDBH->prepare($sql1);

		$sth->execute();

		my @rowArray;
		my $rowCounter = 1;

		while ( @rowArray = $sth->fetchrow_array() ) {

			print "\n* dietemplateId @rowArray[0] : \"@rowArray[1]\" \n";

			$rowCounter++;

		}

		$sth->finish();   # end statement, release resources (not a transaction)
		$slowDBH->disconnect();

		$rowCounter--;
		print("\nListed $rowCounter exception templates.\n");

	};

	if ($@) {
		logEvent( 2, "\nDatabase error: $DBI::errstr" );
		exit 1;
	}

}

sub fnCEEtemplateListAll {

	# list all existing client error templates
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

		my $sql1 = <<DELIMITER1;
SELECT DL_ID,DS_NAME
  FROM TA_CEEXCEPTION_TEMPLATES
  ORDER BY DL_ID
DELIMITER1

		my $sth = $slowDBH->prepare($sql1);

		$sth->execute();

		my @rowArray;
		my $rowCounter = 1;

		while ( @rowArray = $sth->fetchrow_array() ) {

			print "\n* ceetemplateId @rowArray[0] : \"@rowArray[1]\" \n";

			$rowCounter++;

		}

		$sth->finish();   # end statement, release resources (not a transaction)
		$slowDBH->disconnect();

		$rowCounter--;
		print("\nListed $rowCounter exception templates.\n");

	};

	if ($@) {
		logEvent( 2, "\nDatabase error: $DBI::errstr" );
		exit 1;
	}

}

sub fnClientAdd {

# add a new client to the system (can be added manually or will get automatically added when a new client name occurs while parsing backup log files)

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

		$slowDBH->{PrintError} =
		  0;    # we handle/report exceptions ourselves in here

		# use parametrized query - its safer, cleaner and more convenient
		my $sth =
		  $slowDBH->prepare("INSERT INTO TA_CLIENTS (DS_NAME) VALUES (?)");
		my $rows_affected = $sth->execute($currentClientName);
		$sth->finish();   # end statement, release resources (not a transaction)

		$currentClientId = getHighestTableID("TA_CLIENTS");

		$slowDBH->disconnect();

		print("Added $rows_affected rows. ClientId is $currentClientId.\n");

	};

	if ($@) {
		logEvent( 2, "Database error: $DBI::errstr" );
		exit 1;
	}

}

sub fnCEEtemplateAdd {

	# create a new client error template

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

		$slowDBH->{PrintError} =
		  0;    # we handle/report exceptions ourselves in here

		# use parametrized query - its safer, cleaner and more convenient
		my $sth =
		  $slowDBH->prepare(
			"INSERT INTO TA_CEEXCEPTION_TEMPLATES (DS_NAME) VALUES (?)");
		my $rows_affected = $sth->execute($currentCEEtemplateName);
		$sth->finish();   # end statement, release resources (not a transaction)

		$currentCEEtemplateId = getHighestTableID("TA_CEEXCEPTION_TEMPLATES");

		$slowDBH->disconnect();

		print(
"Added $rows_affected rows. CeetemplateId is $currentCEEtemplateId.\n"
		);

	};

	if ($@) {
		logEvent( 2, "Database error: $DBI::errstr" );
		exit 1;
	}

}

sub fnDIEtemplateAdd {

	# add a directory/item exception template to the system

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

		$slowDBH->{PrintError} =
		  0;    # we handle/report exceptions ourselves in here

		# use parametrized query - its safer, cleaner and more convenient
		my $sth =
		  $slowDBH->prepare(
			"INSERT INTO TA_DIEXCEPTION_TEMPLATES (DS_NAME) VALUES (?)");
		my $rows_affected = $sth->execute($currentDIEtemplateName);
		$sth->finish();   # end statement, release resources (not a transaction)

		$currentDIEtemplateId = getHighestTableID("TA_DIEXCEPTION_TEMPLATES");

		$slowDBH->disconnect();

		print(
"Added $rows_affected rows. DietemplateId is $currentDIEtemplateId.\n"
		);

	};

	if ($@) {
		logEvent( 2, "Database error: $DBI::errstr" );
		exit 1;
	}

}

sub fnCEExceptionListAll
{    # list all client error exceptions contained by the specified template

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

		my $sql1 = <<DELIMITER1;
		
SELECT A.DL_ID,
       A.DS_ERROR_CODE,
       B.DL_ID,
       B.DS_NAME
  FROM TA_CEEXCEPTIONS A
       LEFT JOIN TA_CEEXCEPTION_TEMPLATES B
              ON A.DL_EXCEPTION_TEMPLATE_ID = B.DL_ID
 WHERE A.DL_EXCEPTION_TEMPLATE_ID = ?;

DELIMITER1

		my $sth = $slowDBH->prepare($sql1);

		$sth->execute($currentCEEtemplateId);

		my @rowArray;
		my $rowCounter = 1;

		while ( @rowArray = $sth->fetchrow_array() ) {

			if ( $rowCounter == 1 ) {
				print
				  "\nceetemplateId @rowArray[2] [@rowArray[3]] contents : \n";
			}

			print " ceexceptionId @rowArray[0] : \"@rowArray[1]\" \n";

			$rowCounter++;

		}

		$sth->finish();   # end statement, release resources (not a transaction)
		$slowDBH->disconnect();

		$rowCounter--;
		print("\nListed $rowCounter exceptions.\n");

	};

	if ($@) {
		logEvent( 2, "\nDatabase error: $DBI::errstr" );
		exit 1;
	}

}

sub fnDIExceptionListAll {

	# list all directory/item exceptions contained by the specified template

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

		my $sql1 = <<DELIMITER1;
		
SELECT A.DL_ID,
       A.DS_ITEM_PATH,
       B.DL_ID,
       B.DS_NAME
  FROM TA_DIEXCEPTIONS A
       LEFT JOIN TA_DIEXCEPTION_TEMPLATES B
              ON A.DL_EXCEPTION_TEMPLATE_ID = B.DL_ID
 WHERE A.DL_EXCEPTION_TEMPLATE_ID = ?;

DELIMITER1

		my $sth = $slowDBH->prepare($sql1);

		$sth->execute($currentDIEtemplateId);

		my @rowArray;
		my $rowCounter = 1;

		while ( @rowArray = $sth->fetchrow_array() ) {

			if ( $rowCounter == 1 ) {
				print
				  "\ndietemplateId @rowArray[2] [@rowArray[3]] contents : \n";
			}

			print " diexceptionId @rowArray[0] : \"@rowArray[1]\" \n";

			$rowCounter++;

		}

		$sth->finish();   # end statement, release resources (not a transaction)
		$slowDBH->disconnect();

		$rowCounter--;
		print("\nListed $rowCounter exceptions.\n");

	};

	if ($@) {
		logEvent( 2, "\nDatabase error: $DBI::errstr" );
		exit 1;
	}

}

sub fnCEExceptionAdd {

	# add client error exception to the specified template

	my $question =
"This will add exception \"$currentCEExceptionErrorCode\" to template with ceetemplateId $currentCEEtemplateId and affect client error exceptions of its assigned clients. Proceed?";

	if ( askQuestionYN($question) ) {

		eval {

			# connect to database

			if ( !-f $slowDatabaseFileName ) {
				logEvent( 2,
					"Database file $slowDatabaseFileName does not exist" );
				exit 1;
			}

			$slowDBH = DBI->connect(
				"dbi:SQLite:dbname=$slowDatabaseFileName",
				"", "", { RaiseError => 1 },
			);

			$slowDBH->{PrintError} =
			  0;    # we handle/report exceptions ourselves in here

			# use parametrized query - its safer, cleaner and more convenient
			my $sth =
			  $slowDBH->prepare(
"INSERT INTO TA_CEEXCEPTIONS (DL_EXCEPTION_TEMPLATE_ID,DS_ERROR_CODE) VALUES (?,?)"
			  );

			logEvent( 1,
				"currentCEExceptionErrorCode: "
				  . $currentCEExceptionErrorCode );

			my $rows_affected =
			  $sth->execute( $currentCEEtemplateId,
				$currentCEExceptionErrorCode );
			$sth->finish()
			  ;    # end statement, release resources (not a transaction)

			$currentCEExceptionId = getHighestTableID("TA_CEEXCEPTIONS");

			$slowDBH->disconnect();

			print(
"Added $rows_affected rows. CeexceptionId is $currentCEExceptionId.\n"
			);

		};

		if ($@) {
			logEvent( 2, "Database error: $DBI::errstr" );
			exit 1;
		}

	}

}

sub fnDIExceptionAdd {

	# add a new directory/item exception to the specified template

	my $question =
"This will add exception \"$currentDIExceptionPath\" to template with dietemplateId $currentDIEtemplateId and affect directory/item exceptions of its assigned clients. Proceed?";

	if ( askQuestionYN($question) ) {

		eval {

			# connect to database

			if ( !-f $slowDatabaseFileName ) {
				logEvent( 2,
					"Database file $slowDatabaseFileName does not exist" );
				exit 1;
			}

			$slowDBH = DBI->connect(
				"dbi:SQLite:dbname=$slowDatabaseFileName",
				"", "", { RaiseError => 1 },
			);

			$slowDBH->{PrintError} =
			  0;    # we handle/report exceptions ourselves in here

			# use parametrized query - its safer, cleaner and more convenient
			my $sth =
			  $slowDBH->prepare(
"INSERT INTO TA_DIEXCEPTIONS (DL_EXCEPTION_TEMPLATE_ID,DS_ITEM_PATH) VALUES (?,?)"
			  );

			#$currentDIExceptionPath='F:\Backup\Internal\06W8F5SCSR01';

			logEvent( 1, "currentExceptionPath: " . $currentDIExceptionPath );

			my $rows_affected =
			  $sth->execute( $currentDIEtemplateId, $currentDIExceptionPath );
			$sth->finish()
			  ;    # end statement, release resources (not a transaction)

			$currentDIExceptionId = getHighestTableID("TA_DIEXCEPTIONS");

			$slowDBH->disconnect();

			print(
"Added $rows_affected rows. DiexceptionId is $currentDIExceptionId.\n"
			);

		};

		if ($@) {
			logEvent( 2, "Database error: $DBI::errstr" );
			exit 1;
		}

	}

}

sub fnCEExceptionRemove {

	# remove the specified client error exception from its template

	my $question =
"This will remove ceexceptionId $currentCEExceptionId from its template and affect client error exceptions of assigned clients. Proceed?";

	if ( askQuestionYN($question) ) {

		eval {

			# connect to database

			if ( !-f $slowDatabaseFileName ) {
				logEvent( 2,
					"Database file $slowDatabaseFileName does not exist" );
				exit 1;
			}

			$slowDBH = DBI->connect(
				"dbi:SQLite:dbname=$slowDatabaseFileName",
				"", "", { RaiseError => 1 },
			);

# implement this later - so there are no unused hanging values in redundant data lookup
#		removeValueFromRedundantDataLookup( $exceptionPath,
#			\$exceptionPath_LookupIndex );

			# use parametrized query - its safer, cleaner and more convenient

			my $sth =
			  $slowDBH->prepare("DELETE FROM TA_CEEXCEPTIONS WHERE DL_ID=?");
			my $rows_affected = $sth->execute($currentCEExceptionId);
			$sth->finish()
			  ;    # end statement, release resources (not a transaction)

			$slowDBH->disconnect();

			if ( $rows_affected == 0 ) {
				$rows_affected = 0;
			}

			logEvent( 1, "Removed $rows_affected rows." );

		};

		if ($@) {
			logEvent( 2, "Database error: $DBI::errstr" );
			exit 1;
		}

	}
}

sub fnDIExceptionRemove {

	# remove the specified directory/item exception template from its template

	my $question =
"This will remove diexceptionId $currentDIExceptionId from its template and affect directory/item exceptions of assigned clients. Proceed?";

	if ( askQuestionYN($question) ) {

		eval {

			# connect to database

			if ( !-f $slowDatabaseFileName ) {
				logEvent( 2,
					"Database file $slowDatabaseFileName does not exist" );
				exit 1;
			}

			$slowDBH = DBI->connect(
				"dbi:SQLite:dbname=$slowDatabaseFileName",
				"", "", { RaiseError => 1 },
			);

# implement this later - so there are no unused hanging values in redundant data lookup
#		removeValueFromRedundantDataLookup( $exceptionPath,
#			\$exceptionPath_LookupIndex );

			# use parametrized query - its safer, cleaner and more convenient

			my $sth =
			  $slowDBH->prepare("DELETE FROM TA_DIEXCEPTIONS WHERE DL_ID=?");
			my $rows_affected = $sth->execute($currentDIExceptionId);
			$sth->finish()
			  ;    # end statement, release resources (not a transaction)

			$slowDBH->disconnect();

			if ( $rows_affected == 0 ) {
				$rows_affected = 0;
			}

			logEvent( 1, "Removed $rows_affected rows." );

		};

		if ($@) {
			logEvent( 2, "Database error: $DBI::errstr" );
			exit 1;
		}

	}

}

sub isInteger {
	my $val = shift;
	return ( $val =~ /^[+-]?\d+$/ );
}

sub storeValueInRedundantDataLookup {
	my ( $data1, $index1 )
	  =    # expects reference to variable $index1 (so it can modify it)
	  @_;
	my $sth;

	$slowDBH->{PrintError} = 0;
	eval
	{ # this ensures flow in cases that the same data were already stored in TA_REDUNDANT_DATA_LOOKUP

		$sth =
		  $slowDBH->prepare(
			"INSERT INTO TA_REDUNDANT_DATA_LOOKUP (DS_DATA) VALUES (?)");

		$sth->execute($data1);
	};
	$slowDBH->{PrintError} = 1;

	#logEvent( 1, "next" );

	$sth->finish();    # end statement, release resources (not a transaction)

	$sth =
	  $slowDBH->prepare(
		"SELECT DL_ID FROM TA_REDUNDANT_DATA_LOOKUP WHERE DS_DATA=?");
	$sth->execute($data1);
	my $tmp1 = $sth->fetch();
	$$index1 =
	  @$tmp1[0]
	  ; # dereference array referenced by $tmp1, retrieve its first item and store it in a scalar variable that is referenced by $value1

	$sth->finish();    # end statement, release resources (not a transaction)

}

sub askQuestionYN() {
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

sub evaluateReportProblems1 {
	my ( $reportId, $itemProblemCount, $itemDirectoriesProblemCount,
		$ignoredItemProblemCount, $ignoredItemDirectoriesProblemCount )
	  = # expects reference to variables $unfilteredItemProblemCount, $unfilteredItemDirectoriesProblemCount (so it can modify them)
	  @_;
	my $sth;
	my $tmp1;

	# count problematic items, apply filter  (templates/exceptions)

	my $sql1 = <<DELIMITER1;

SELECT COUNT( 1 )
  FROM TA_JOB_ITEMS A, 
       TA_JOBS E
 WHERE A.DL_JOB_ID = E.DL_ID 
       AND
       E.DL_REPORT_ID = ? 
       AND
       NOT EXISTS ( 
           SELECT 1
             FROM TA_DIEXCEPTIONS B, 
                  TA_DIEXCEPTION_TEMPLATES_MATCHING C, 
                  TA_REDUNDANT_DATA_LOOKUP D
            WHERE B.DL_EXCEPTION_TEMPLATE_ID = C.DL_EXCEPTION_TEMPLATE_ID 
                  AND
                  E.DL_CLIENT_ID = C.DL_CLIENT_ID 
                  AND
                  A.DL_ITEM_PATH_ID = D.DL_ID 
                  AND
                  INSTR( D.DS_DATA, B.DS_ITEM_PATH ) = 1 
       );
       
DELIMITER1

	$sth = $slowDBH->prepare($sql1);

	$sth->execute($reportId);

	$tmp1 = $sth->fetch();

	$sth->finish();    # end statement, release resources (not a transaction)

	$$itemProblemCount =
	  @$tmp1[0]
	  ; # dereference array referenced by $tmp1, retrieve its first item and store it in a scalar variable that is referenced by $value1

# count directories which had problematic items, apply filter (templates/exceptions)

	my $sql1 = <<DELIMITER1;

SELECT COUNT( DL_ITEM_PATH_ID )
  FROM ( 
    SELECT DISTINCT ( DL_ITEM_PATH_ID )
               FROM TA_JOB_ITEMS A, 
                    TA_JOBS E
              WHERE A.DL_JOB_ID = E.DL_ID 
                    AND
                    E.DL_REPORT_ID = ? 
                    AND
                    NOT EXISTS ( 
                        SELECT 1
                          FROM TA_DIEXCEPTIONS B, 
                               TA_DIEXCEPTION_TEMPLATES_MATCHING C, 
                               TA_REDUNDANT_DATA_LOOKUP D
                         WHERE B.DL_EXCEPTION_TEMPLATE_ID = C.DL_EXCEPTION_TEMPLATE_ID 
                               AND
                               E.DL_CLIENT_ID = C.DL_CLIENT_ID 
                               AND
                               A.DL_ITEM_PATH_ID = D.DL_ID 
                               AND
                               INSTR( D.DS_DATA, B.DS_ITEM_PATH ) = 1 
                    ) 
                     
);
 
DELIMITER1

	$sth = $slowDBH->prepare($sql1);

	$sth->execute($reportId);

	$tmp1 = $sth->fetch();

	$sth->finish();    # end statement, release resources (not a transaction)

	$$itemDirectoriesProblemCount =
	  @$tmp1[0]
	  ; # dereference array referenced by $tmp1, retrieve its first item and store it in a scalar variable that is referenced by $value1

	# count problematic items, do not filter
	$sth =
	  $slowDBH->prepare(
"SELECT COUNT(1) FROM TA_JOB_ITEMS A,TA_JOBS B WHERE A.DL_JOB_ID=B.DL_ID AND B.DL_REPORT_ID=?"
	  );

	$sth->execute($reportId);

	$tmp1 = $sth->fetch();

	$sth->finish();    # end statement, release resources (not a transaction)

	$$ignoredItemProblemCount = @$tmp1[0] - $$itemProblemCount;

	# count directories which had problematic items, do not filter

	$sth =
	  $slowDBH->prepare(
"SELECT COUNT(1) FROM (SELECT DISTINCT(DL_ITEM_PATH_ID) FROM TA_JOB_ITEMS A,TA_JOBS B WHERE A.DL_JOB_ID=B.DL_ID AND B.DL_REPORT_ID=?)"
	  );

	$sth->execute($reportId);

	$tmp1 = $sth->fetch();

	$sth->finish();    # end statement, release resources (not a transaction)

	$$ignoredItemDirectoriesProblemCount =
	  @$tmp1[0] - $$itemDirectoriesProblemCount;

}

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

		my $sql1 =
		  "UPDATE TA_SETTINGS SET DS_VALUE=\"$value1\" WHERE DS_KEY=\"$key1\"";

		my $sth = $fastDBHTmp->prepare($sql1);

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

############

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

sub getHighestTableID {
	my ($tableName) = @_;
	my $returnValue = 0
	  ; # 0 is never a valid value (this function is only to be used to return index of last inserted row in a table)

	eval {
		my $sth = $slowDBH->prepare( "SELECT MAX(DL_ID) FROM " . $tableName );
		$sth->execute();
		my $tmp1 = $sth->fetch();
		$returnValue = @$tmp1[0];
		$sth->finish();   # end statement, release resources (not a transaction)

	};

	if ($@) {

		logEvent( 2, "Error 1 occured in getHighestTableID(): $@" );

	}

	return $returnValue;

}

sub getNewSlowDatabaseCreationStatement {
	my $result1 = <<DELIMITER1;


-- Table: TA_STORAGE_POLICIES
CREATE TABLE TA_STORAGE_POLICIES ( 
    DL_ID   INTEGER PRIMARY KEY AUTOINCREMENT,
    DS_NAME TEXT    UNIQUE
                    COLLATE 'NOCASE' 
);


-- Table: TA_SUBCLIENTS
CREATE TABLE TA_SUBCLIENTS ( 
    DL_ID   INTEGER PRIMARY KEY AUTOINCREMENT,
    DS_NAME TEXT    UNIQUE
                    COLLATE 'NOCASE' 
);


-- Table: TA_CLIENTS
CREATE TABLE TA_CLIENTS ( 
    DL_ID   INTEGER PRIMARY KEY AUTOINCREMENT,
    DS_NAME TEXT    UNIQUE
                    COLLATE 'NOCASE'                
);


-- Table: TA_REPORTS
CREATE TABLE TA_REPORTS ( 
    DL_ID              INTEGER  PRIMARY KEY AUTOINCREMENT,
    DS_FILENAME        TEXT     COLLATE 'NOCASE',
    DT_IMPORT_STARTED  DATETIME DEFAULT ( ( datetime( 'now', 'localtime' )  )  ),
    DT_IMPORT_FINISHED DATETIME 
);


-- Table: TA_JOBS
CREATE TABLE TA_JOBS ( 
    DL_ID                          INTEGER PRIMARY KEY AUTOINCREMENT,
    DL_REPORT_ID                   INTEGER NOT NULL
                                           REFERENCES TA_REPORTS ( DL_ID ) ON DELETE RESTRICT
                                                                           ON UPDATE RESTRICT
                                                                           MATCH FULL,
    DL_CLIENT_ID                   INTEGER REFERENCES TA_CLIENTS ( DL_ID ) ON DELETE RESTRICT
                                                                           ON UPDATE RESTRICT
                                                                           MATCH FULL,
    DS_AGENT                       TEXT,
    DS_INSTANCE                    TEXT,
    DS_BACKUP_SET                  TEXT,
    DL_SUBCLIENT_ID                INTEGER REFERENCES TA_SUBCLIENTS ( DL_ID ) ON DELETE RESTRICT
                                                                              ON UPDATE RESTRICT
                                                                              MATCH FULL,
    DL_STORAGE_POLICY_ID           INTEGER REFERENCES TA_STORAGE_POLICIES ( DL_ID ) ON DELETE RESTRICT
                                                                                    ON UPDATE RESTRICT
                                                                                    MATCH FULL,
    DS_JOBID                       TEXT,
    DS_STATUS                      TEXT,
    DS_TYPE                        TEXT,
    DS_SCAN_TYPE                   TEXT,
    DS_START_TIME                  TEXT,
    DS_WRITE_START_TIME            TEXT,
    DS_END_TIME_OR_CURRENT_PHASE   TEXT,
    DS_WRITE_END_TIME              TEXT,
    DS_SIZE_OF_APPLICATION         TEXT,
    DS_COMPRESSION_RATE            TEXT,
    DS_DATA_TRANSFERRED			   TEXT,
    DS_DATA_WRITTEN			       TEXT,
    DS_SPACE_SAVING_PERCENTAGE     TEXT,
    DS_DATA_SIZE_CHANGE			   TEXT,
    DS_TRANSFER_TIME               TEXT,
    DS_CURRENT_TRANSFER_TIME       TEXT,
    DS_THROUGHPUT                  TEXT,
    DS_CURRENT_THROUGHPUT          TEXT,
    DS_PROTECTED_OBJECTS           TEXT,
    DS_FAILED_OBJECTS              TEXT,
    DS_FAILED_FOLDERS              TEXT,
    DS_MEDIA_AGENT                 TEXT,
    DS_SUBCLIENT_CONTENT           TEXT,
    DS_SCAN_TYPE_CHANGE_REASON     TEXT,
    DS_FAILURE_REASON              TEXT,
    DS_JOB_DESCRIPTION             TEXT,
    DS_FAILURE_ERROR_CODE          TEXT 
);



-- Table: TA_REDUNDANT_DATA_LOOKUP
CREATE TABLE TA_REDUNDANT_DATA_LOOKUP ( 
    DL_ID   INTEGER PRIMARY KEY AUTOINCREMENT,
    DS_DATA TEXT    UNIQUE 
);


-- Table: TA_DIEXCEPTION_TEMPLATES
CREATE TABLE TA_DIEXCEPTION_TEMPLATES ( 
    DL_ID   INTEGER PRIMARY KEY AUTOINCREMENT,
    DS_NAME TEXT    UNIQUE
                    COLLATE 'NOCASE' 
);


-- Table: TA_DIEXCEPTION_TEMPLATES_MATCHING
CREATE TABLE TA_DIEXCEPTION_TEMPLATES_MATCHING ( 
    DL_ID                    INTEGER PRIMARY KEY AUTOINCREMENT,
    DL_EXCEPTION_TEMPLATE_ID INTEGER REFERENCES TA_DIEXCEPTION_TEMPLATES ( DL_ID ) ON DELETE RESTRICT
                                                                                   ON UPDATE RESTRICT
                                                                                   MATCH FULL,
    DL_CLIENT_ID             INTEGER REFERENCES TA_CLIENTS ( DL_ID ) ON DELETE RESTRICT
                                                                     ON UPDATE RESTRICT
                                                                     MATCH FULL 
);


-- Table: TA_DIEXCEPTIONS
CREATE TABLE TA_DIEXCEPTIONS ( 
    DL_ID                    INTEGER PRIMARY KEY AUTOINCREMENT,
    DS_ITEM_PATH             TEXT,
    DL_EXCEPTION_TEMPLATE_ID INTEGER REFERENCES TA_DIEXCEPTION_TEMPLATES ( DL_ID ) ON DELETE RESTRICT
                                                                                   ON UPDATE RESTRICT
                                                                                   MATCH FULL 
);


-- Table: TA_JOB_ITEMS
CREATE TABLE TA_JOB_ITEMS ( 
    DL_ID             INTEGER PRIMARY KEY AUTOINCREMENT,
    DL_JOB_ID         INTEGER NOT NULL
                              REFERENCES TA_JOBS ( DL_ID ) ON DELETE RESTRICT
                                                           ON UPDATE RESTRICT
                                                           MATCH FULL,
    DL_ITEM_PATH_ID   INTEGER NOT NULL
                              REFERENCES TA_REDUNDANT_DATA_LOOKUP ( DL_ID ) ON DELETE RESTRICT
                                                                            ON UPDATE RESTRICT
                                                                            MATCH FULL,
    DL_ITEM_NAME_ID   INTEGER NOT NULL
                              REFERENCES TA_REDUNDANT_DATA_LOOKUP ( DL_ID ) ON DELETE RESTRICT
                                                                            ON UPDATE RESTRICT
                                                                            MATCH FULL,
    DL_ITEM_REASON_ID INTEGER NOT NULL
                              REFERENCES TA_REDUNDANT_DATA_LOOKUP ( DL_ID ) ON DELETE RESTRICT
                                                                            ON UPDATE RESTRICT
                                                                            MATCH FULL 
);


-- Table: TA_CEEXCEPTION_TEMPLATES
CREATE TABLE TA_CEEXCEPTION_TEMPLATES ( 
    DL_ID   INTEGER PRIMARY KEY AUTOINCREMENT,
    DS_NAME TEXT    UNIQUE
                    COLLATE 'NOCASE' 
);


-- Table: TA_CEEXCEPTION_TEMPLATES_MATCHING
CREATE TABLE TA_CEEXCEPTION_TEMPLATES_MATCHING ( 
    DL_ID                    INTEGER PRIMARY KEY AUTOINCREMENT,
    DL_EXCEPTION_TEMPLATE_ID INTEGER REFERENCES TA_DIEXCEPTION_TEMPLATES ( DL_ID ) ON DELETE RESTRICT
                                                                                   ON UPDATE RESTRICT
                                                                                   MATCH FULL,
    DL_CLIENT_ID             INTEGER REFERENCES TA_CLIENTS ( DL_ID ) ON DELETE RESTRICT
                                                                     ON UPDATE RESTRICT
                                                                     MATCH FULL 
);


-- Table: TA_CEEXCEPTIONS
CREATE TABLE TA_CEEXCEPTIONS ( 
    DL_ID                    INTEGER PRIMARY KEY AUTOINCREMENT,
    DS_ERROR_CODE            TEXT,
    DL_EXCEPTION_TEMPLATE_ID INTEGER REFERENCES TA_DIEXCEPTION_TEMPLATES ( DL_ID ) ON DELETE RESTRICT
                                                                                   ON UPDATE RESTRICT
                                                                                   MATCH FULL 
);


-- Index: idx_TA_REDUNDANT_DATA_LOOKUP
CREATE INDEX idx_TA_REDUNDANT_DATA_LOOKUP ON TA_REDUNDANT_DATA_LOOKUP ( 
    DS_DATA 
);



-- Index: idx_TA_DIEXCEPTION_TEMPLATES_MATCHING1
CREATE INDEX idx_TA_DIEXCEPTION_TEMPLATES_MATCHING1 ON TA_DIEXCEPTION_TEMPLATES_MATCHING ( 
    DL_EXCEPTION_TEMPLATE_ID 
);


-- Index: idx_TA_DIEXCEPTION_TEMPLATES_MATCHING2
CREATE INDEX idx_TA_DIEXCEPTION_TEMPLATES_MATCHING2 ON TA_DIEXCEPTION_TEMPLATES_MATCHING ( 
    DL_CLIENT_ID 
);


-- Index: idx_TA_JOBS1
CREATE INDEX idx_TA_JOBS1 ON TA_JOBS ( 
    DL_REPORT_ID 
);


-- Index: idx_TA_JOBS2
CREATE INDEX idx_TA_JOBS2 ON TA_JOBS ( 
    DL_CLIENT_ID 
);


-- Index: idx_TA_JOBS3
CREATE INDEX idx_TA_JOBS3 ON TA_JOBS ( 
    DL_SUBCLIENT_ID 
);


-- Index: idx_TA_JOBS4
CREATE INDEX idx_TA_JOBS4 ON TA_JOBS ( 
    DL_STORAGE_POLICY_ID 
);


-- Index: idx_TA_REPORTS2
CREATE INDEX idx_TA_REPORTS2 ON TA_REPORTS ( 
    DT_IMPORT_STARTED 
);


-- Index: idx_TA_REPORTS1
CREATE INDEX idx_TA_REPORTS1 ON TA_REPORTS ( 
    DS_FILENAME 
);


-- Index: idx_TA_REPORTS3
CREATE INDEX idx_TA_REPORTS3 ON TA_REPORTS ( 
    DT_IMPORT_FINISHED 
);


-- Index: idx_TA_DIEXCEPTIONS1
CREATE INDEX idx_TA_DIEXCEPTIONS1 ON TA_DIEXCEPTIONS ( 
    DL_EXCEPTION_TEMPLATE_ID 
);


-- Index: idx_TA_JOB_ITEMS2
CREATE INDEX idx_TA_JOB_ITEMS2 ON TA_JOB_ITEMS ( 
    DL_JOB_ID 
);


-- Index: idx_TA_JOB_ITEMS3
CREATE INDEX idx_TA_JOB_ITEMS3 ON TA_JOB_ITEMS ( 
    DL_ITEM_PATH_ID 
);


-- Index: idx_TA_JOB_ITEMS4
CREATE INDEX idx_TA_JOB_ITEMS4 ON TA_JOB_ITEMS ( 
    DL_ITEM_NAME_ID 
);


-- Index: idx_TA_JOB_ITEMS5
CREATE INDEX idx_TA_JOB_ITEMS5 ON TA_JOB_ITEMS ( 
    DL_ITEM_REASON_ID 
);


-- Index: idx_TA_CEEXCEPTION_TEMPLATES_MATCHING1
CREATE INDEX idx_TA_CEEXCEPTION_TEMPLATES_MATCHING1 ON TA_CEEXCEPTION_TEMPLATES_MATCHING ( 
    DL_EXCEPTION_TEMPLATE_ID 
);


-- Index: idx_TA_CEEXCEPTION_TEMPLATES_MATCHING2
CREATE INDEX idx_TA_CEEXCEPTION_TEMPLATES_MATCHING2 ON TA_CEEXCEPTION_TEMPLATES_MATCHING ( 
    DL_CLIENT_ID 
);


-- Index: idx_TA_CEEXCEPTION_TEMPLATES_MATCHING-Concatenatedkey-unique1
CREATE INDEX [idx_TA_CEEXCEPTION_TEMPLATES_MATCHING-Concatenatedkey-unique1] ON TA_CEEXCEPTION_TEMPLATES_MATCHING ( 
    DL_EXCEPTION_TEMPLATE_ID,
    DL_CLIENT_ID 
);


-- Index: idx_TA_DIEXCEPTION_TEMPLATES_MATCHING-Concatenatedkey-unique1
CREATE UNIQUE INDEX [idx_TA_DIEXCEPTION_TEMPLATES_MATCHING-Concatenatedkey-unique1] ON TA_DIEXCEPTION_TEMPLATES_MATCHING ( 
    DL_EXCEPTION_TEMPLATE_ID,
    DL_CLIENT_ID 
);


-- Index: idx_TA_CEEXCEPTIONS1
CREATE INDEX idx_TA_CEEXCEPTIONS1 ON TA_CEEXCEPTIONS ( 
    DL_EXCEPTION_TEMPLATE_ID 
);


DELIMITER1

	return $result1;

}

sub getNewFastDatabaseCreationStatement {
	my $result1 = <<DELIMITER1;



-- Table: TA_DROPBOX
CREATE TABLE TA_DROPBOX ( 
    DS_KEY         TEXT PRIMARY KEY
                        COLLATE 'NOCASE',
    DS_VALUE       TEXT,
    DS_DESCRIPTION TEXT 
);


INSERT INTO [TA_DROPBOX] ([DS_KEY], [DS_VALUE], [DS_DESCRIPTION]) VALUES ('4RE1T', '', 'Refer to job containing 4RE1T in TA_SCHEDULER');
INSERT INTO [TA_DROPBOX] ([DS_KEY], [DS_VALUE], [DS_DESCRIPTION]) VALUES ('T1KK3', '', 'Refer to job containing T1KK3 in TA_SCHEDULER');
INSERT INTO [TA_DROPBOX] ([DS_KEY], [DS_VALUE], [DS_DESCRIPTION]) VALUES ('C93V1', '', 'Refer to job containing C93V1 in TA_SCHEDULER');




-- Table: TA_SETTINGS
CREATE TABLE TA_SETTINGS ( 
    DS_KEY         TEXT PRIMARY KEY
                        COLLATE 'NOCASE',
    DS_VALUE       TEXT,
    DS_DESCRIPTION TEXT 
);

INSERT INTO [TA_SETTINGS] ([DS_KEY], [DS_VALUE], [DS_DESCRIPTION]) VALUES ('DATABASE_MAX_DATA_SIZE', 2000000000, 'maximum approximate amount of data held in database.This does not refer to database file size (which can be vacuumed) but rather to total used internal space (utilized by all valid/non-deleted database pages)');
INSERT INTO [TA_SETTINGS] ([DS_KEY], [DS_VALUE], [DS_DESCRIPTION]) VALUES ('REPORT_FILES_RETENTION_PERIOD', 14, 'in days');
INSERT INTO [TA_SETTINGS] ([DS_KEY], [DS_VALUE], [DS_DESCRIPTION]) VALUES ('THIS_DATABASE_VERSION', '2.1', 'just to keep the track of this database changes');
INSERT INTO [TA_SETTINGS] ([DS_KEY], [DS_VALUE], [DS_DESCRIPTION]) VALUES ('COMPATIBILITY_INFO', '
This info has been generated by diag-n-maintain.pl version 2.1:
* compatible with diag-n-maintain.pl versions 2.1.x
* compatible with harvest-logs.pl versions 2.1.x
* compatible with analyze-data.pl versions 2.1.x
* compatible with get-data.pl versions 2.1.x
* compatible with scheduler.pl versions 2.1.x
* compatible with database version 2.1.x
* tested on TBA
Please report any inconsistencies to Premysl Botek / Premek at premysl.botek(at)lab.com. Ta!
', '');
INSERT INTO [TA_SETTINGS] ([DS_KEY], [DS_VALUE], [DS_DESCRIPTION]) VALUES ('DATA_IMPORT_DIRECTORY', '/clmdata/bkp', 'thats where the log files are stored by Backup Agent');
INSERT INTO [TA_SETTINGS] ([DS_KEY], [DS_VALUE], [DS_DESCRIPTION]) VALUES ('SCHEDULER_LOCK', 'nil', 'Values: "nil" or lock_timestamp. Prevents more than one instance of scheduler to run at a time.');
INSERT INTO [TA_SETTINGS] ([DS_KEY], [DS_VALUE], [DS_DESCRIPTION]) VALUES ('SCHEDULER_STATUS', 'sleeping', 'Values: "idle" or current status of scheduler');
INSERT INTO [TA_SETTINGS] ([DS_KEY], [DS_VALUE], [DS_DESCRIPTION]) VALUES ('WEB_APP_URL', 'http://hmspsydzproxclm01.harbour/clmonitoring/', 'Specifies full address of the PHP scripts. Must be located on the same machine with database');






-- Table: TA_SCHEDULER
CREATE TABLE TA_SCHEDULER ( 
    DL_ID             INTEGER  PRIMARY KEY AUTOINCREMENT,
    DL_ORDER_NUMBER   INTEGER  UNIQUE,
    DS_COMMAND_LINE   TEXT,
    DT_LAST_COMPLETED DATETIME DEFAULT ( ( datetime( 'now', 'localtime' )  )  ),
    DL_RUN_INTERVAL   INTEGER  NOT NULL
                               DEFAULT ( 60 ),
    DL_LAST_RESULT_CODE	INTEGER,
    DS_LAST_RESULT    TEXT,
    DS_DESCRIPTION   TEXT
    
);

INSERT INTO [TA_SCHEDULER] ([DL_ID], [DL_ORDER_NUMBER], [DS_COMMAND_LINE], [DT_LAST_COMPLETED], [DL_RUN_INTERVAL], [DS_LAST_RESULT], [DS_DESCRIPTION]) VALUES (1, 1, 'harvest-logs.pl', '2013-12-18 10:49:23', 60, null,'Harvests log files that have any jobs ready-for-review');
INSERT INTO [TA_SCHEDULER] ([DL_ID], [DL_ORDER_NUMBER], [DS_COMMAND_LINE], [DT_LAST_COMPLETED], [DL_RUN_INTERVAL], [DS_LAST_RESULT], [DS_DESCRIPTION]) VALUES (2, 2, 'analyze-data.pl REPORT DASHBOARD "TODAY,0,TODAY,0,1,1,TODAY,0,TODAY,0,1,TODAY,0,3,4RE1T"', '2013-12-18 10:49:23', 60, null,'Generates Dashboard HTML and stores it in TA_DROPBOX under 4RE1T');
INSERT INTO [TA_SCHEDULER] ([DL_ID], [DL_ORDER_NUMBER], [DS_COMMAND_LINE], [DT_LAST_COMPLETED], [DL_RUN_INTERVAL], [DS_LAST_RESULT], [DS_DESCRIPTION]) VALUES (3, 3, 'analyze-data.pl SUMMARY NUMBEROFCLIENTERRORSFORPERIOD TODAY 0 TODAY 0 T1KK3', '2013-12-18 10:49:23', 60, null,'Gets number of client errors for today and stores it in TA_DROPBOX under T1KK3');
INSERT INTO [TA_SCHEDULER] ([DL_ID], [DL_ORDER_NUMBER], [DS_COMMAND_LINE], [DT_LAST_COMPLETED], [DL_RUN_INTERVAL], [DS_LAST_RESULT], [DS_DESCRIPTION]) VALUES (4, 4, 'analyze-data.pl SUMMARY NUMBEROFCLIENTERRORSXCONSECUTIVEDAYSFROMDAY TODAY 0 3 C93V1', '2013-12-18 10:49:23', 60, null, 'Gets number of clients with 3 consequential errors from today backwards and stores it in TA_DROPBOX under C93V1');





-- Index: idx_TA_DROPBOX
CREATE INDEX idx_TA_DROPBOX ON TA_DROPBOX ( 
    DS_KEY 
);




-- Index: idx_TA_SETTINGS
CREATE INDEX idx_TA_SETTINGS ON TA_SETTINGS ( 
    DS_KEY 
);



DELIMITER1

	return $result1;

}

