#!/usr/bin/perl
#### Monitoring Commvault Backup Logs
#### Version 2.3
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
  "ANALYZE-DATA";    # just for log file record identification purposes

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

# 1 - summary-numberofitemerrorsforperiod
# 2 - metadata-SCRIPTSLOGFILEERRORS
# 3 - summary-numberofclienterrorsforperiod
# 4 - metadata-IMPORTPROCEDURELOCK
# 5 - report-DASHBOARD
# 6 - report-DETAILEDCLIENTERRORSFORPERIOD
# 7 - report DETAILEDCLIENTERRORSXCONSECUTIVEDAYSFROMDAY
# 8 - metadata databasecachingstatus
# 9 - summary-NUMBEROFCLIENTERRORSXCONSECUTIVEDAYSFROMDAY
my $appMode = 0;
my $slowDBH;

#my $fastDBH;
my $invalidCommandLine = 0;

#my $ssh_pipe;
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

logEvent( 1, "Started" );

my $commandline = join " ", $0, @ARGV;
logEvent( 1, "Used command line: $commandline" );

if ( $#ARGV < 1 ) {
	$invalidCommandLine = 1;
}
else {

	$invalidCommandLine = 1;

	given ( uc( $ARGV[0] ) ) {

		when ("REPORT") {

			if ( uc( $ARGV[1] ) eq "DASHBOARD"
				&& defined( $ARGV[2] ) )
			{

# zabbix agent does not support more than 9 user parameters but we need many more
# we pass parameters through agent as one string parameter in quotes and then split them up in here
				my $ARGV1 = "REPORT,DASHBOARD," . $ARGV[2];
				my @ARGV1 = split( /,/, $ARGV1 );

				if (

					isInteger( @ARGV1[3] )
					&& defined( @ARGV1[4] )
					&& isInteger( @ARGV1[5] )
					&& isInteger( @ARGV1[6] )
					&& isInteger( @ARGV1[7] )
					&& defined( @ARGV1[8] )
					&& isInteger( @ARGV1[9] )
					&& defined( @ARGV1[10] )
					&& isInteger( @ARGV1[11] )
					&& isInteger( @ARGV1[12] )
					&& defined( @ARGV1[13] )
					&& isInteger( @ARGV1[14] )
					&& isInteger( @ARGV1[15] )

				  )
				{

					eval {

						if ( uc @ARGV1[2] eq "TODAY" ) {

							$selectedDate1 = getFormatedTodaysDate();

						}
						else {

							$selectedDate1 =
							  Time::Piece->strptime( @ARGV1[2], "%Y-%m-%d" )
							  ;    # just validate by conversion to a time piece
							$selectedDate1 = @ARGV1[2];

						}

						$selectedDate1Offset = @ARGV1[3];

						if ( uc @ARGV1[4] eq "TODAY" ) {

							$selectedDate2 = getFormatedTodaysDate();

						}
						else {

							$selectedDate2 =
							  Time::Piece->strptime( @ARGV1[4], "%Y-%m-%d" )
							  ;    # just validate by conversion to a time piece
							$selectedDate2 = @ARGV1[4];

						}

						$selectedDate2Offset = @ARGV1[5];
						$displayOverallInfo  = @ARGV1[6];

						$displayClientErrorInfo = @ARGV1[7];

						if ( uc @ARGV1[8] eq "TODAY" ) {

							$rdcefpSelectedDate1 = getFormatedTodaysDate();

						}
						else {

							$rdcefpSelectedDate1 =
							  Time::Piece->strptime( @ARGV1[8], "%Y-%m-%d" )
							  ;    # just validate by conversion to a time piece
							$rdcefpSelectedDate1 = @ARGV1[8];

						}

						$rdcefpSelectedDate1Offset = @ARGV1[9];

						if ( uc @ARGV1[10] eq "TODAY" ) {

							$rdcefpSelectedDate2 = getFormatedTodaysDate();

						}
						else {

							$rdcefpSelectedDate2 =
							  Time::Piece->strptime( @ARGV1[10], "%Y-%m-%d" )
							  ;    # just validate by conversion to a time piece
							$rdcefpSelectedDate2 = @ARGV1[10];

						}

						$rdcefpSelectedDate2Offset = @ARGV1[11];

						$displayXConsecutiveClientErrorInfo = @ARGV1[12];

						if ( uc @ARGV1[13] eq "TODAY" ) {

							$rdcefcSelectedDate1 = getFormatedTodaysDate();

						}
						else {

							$rdcefcSelectedDate1 =
							  Time::Piece->strptime( @ARGV1[13], "%Y-%m-%d" )
							  ;    # just validate by conversion to a time piece
							$rdcefcSelectedDate1 = @ARGV1[13];

						}

						$rdcefcSelectedDate1Offset = @ARGV1[14];
						$consecutiveDaysNumber     = @ARGV1[15];

						$currentDropboxId = @ARGV1[16];

						$appMode            = 5;
						$invalidCommandLine = 0;

					  }

				}

			}

			if ( uc( $ARGV[1] ) eq "DETAILEDCLIENTERRORSXCONSECUTIVEDAYSFROMDAY"
				&& defined( $ARGV[2] )
				&& isInteger( $ARGV[3] )
				&& isInteger( $ARGV[4] ) )
			{

				eval {

					if ( uc $ARGV[2] eq "TODAY" ) {

						$rdcefcSelectedDate1 = getFormatedTodaysDate();

					}
					else {

						$rdcefcSelectedDate1 =
						  Time::Piece->strptime( $ARGV[2], "%Y-%m-%d" )
						  ;    # just validate by conversion to a time piece
						$rdcefcSelectedDate1 = $ARGV[2];

					}

					$rdcefcSelectedDate1Offset = $ARGV[3];
					$consecutiveDaysNumber     = $ARGV[4];

					$appMode            = 7;
					$invalidCommandLine = 0;

				  }

			}

			if (   uc( $ARGV[1] ) eq "DETAILEDCLIENTERRORSFORPERIOD"
				&& defined( $ARGV[2] )
				&& isInteger( $ARGV[3] )
				&& defined( $ARGV[4] )
				&& isInteger( $ARGV[5] ) )
			{

				eval {

					if ( uc $ARGV[2] eq "TODAY" ) {

						$rdcefpSelectedDate1 = getFormatedTodaysDate();

					}
					else {

						$rdcefpSelectedDate1 =
						  Time::Piece->strptime( $ARGV[2], "%Y-%m-%d" )
						  ;    # just validate by conversion to a time piece
						$rdcefpSelectedDate1 = $ARGV[2];

					}

					if ( uc $ARGV[4] eq "TODAY" ) {

						$rdcefpSelectedDate2 = getFormatedTodaysDate();

					}
					else {

						$rdcefpSelectedDate2 =
						  Time::Piece->strptime( $ARGV[4], "%Y-%m-%d" )
						  ;    # just validate by conversion to a time piece
						$rdcefpSelectedDate2 = $ARGV[4];

					}

					$rdcefpSelectedDate1Offset = $ARGV[3];
					$rdcefpSelectedDate2Offset = $ARGV[5];

					$currentDropboxId = @ARGV[6];

					$appMode            = 6;
					$invalidCommandLine = 0;

				  }

			}

		}

		when ("METADATA") {

			if ( uc( $ARGV[1] ) eq "SCRIPTSLOGFILEERRORS" ) {

				$appMode            = 2;
				$invalidCommandLine = 0;

			}

			if ( uc( $ARGV[1] ) eq "IMPORTPROCEDURELOCK" ) {

				$appMode            = 4;
				$invalidCommandLine = 0;

			}

			if ( uc( $ARGV[1] ) eq "DATABASECACHINGSTATUS" ) {

				$appMode            = 8;
				$invalidCommandLine = 0;

			}

		}

		when ("SUMMARY") {

			if ( uc( $ARGV[1] ) eq "NUMBEROFCLIENTERRORSXCONSECUTIVEDAYSFROMDAY"
				&& defined( $ARGV[2] )
				&& isInteger( $ARGV[3] )
				&& isInteger( $ARGV[4] ) )
			{

				eval {

					if ( uc $ARGV[2] eq "TODAY" ) {

						$rdcefcSelectedDate1 = getFormatedTodaysDate();

					}
					else {

						$rdcefcSelectedDate1 =
						  Time::Piece->strptime( $ARGV[2], "%Y-%m-%d" )
						  ;    # just validate by conversion to a time piece
						$rdcefcSelectedDate1 = $ARGV[2];

					}

					$rdcefcSelectedDate1Offset = $ARGV[3];
					$consecutiveDaysNumber     = $ARGV[4];

					$currentDropboxId = @ARGV[5];

					$appMode            = 9;
					$invalidCommandLine = 0;

				  }

			}

			if (   uc( $ARGV[1] ) eq "NUMBEROFCLIENTERRORSFORPERIOD"
				&& defined( $ARGV[2] )
				&& isInteger( $ARGV[3] )
				&& defined( $ARGV[4] )
				&& isInteger( $ARGV[5] ) )
			{

				eval {

					if ( uc $ARGV[2] eq "TODAY" ) {

						$selectedDate1 = getFormatedTodaysDate();

					}
					else {

						$selectedDate1 =
						  Time::Piece->strptime( $ARGV[2], "%Y-%m-%d" )
						  ;    # just validate by conversion to a time piece
						$selectedDate1 = $ARGV[2];

					}

					if ( uc $ARGV[4] eq "TODAY" ) {

						$selectedDate2 = getFormatedTodaysDate();

					}
					else {

						$selectedDate2 =
						  Time::Piece->strptime( $ARGV[4], "%Y-%m-%d" )
						  ;    # just validate by conversion to a time piece
						$selectedDate2 = $ARGV[4];

					}

					$selectedDate1Offset = $ARGV[3];
					$selectedDate2Offset = $ARGV[5];

					$currentDropboxId = @ARGV[6];

					$appMode            = 3;
					$invalidCommandLine = 0;

				  }

			}

			if (   uc( $ARGV[1] ) eq "NUMBEROFITEMERRORSFORPERIOD"
				&& defined( $ARGV[2] )
				&& isInteger( $ARGV[3] )
				&& defined( $ARGV[4] )
				&& isInteger( $ARGV[5] ) )
			{

				eval {

					if ( uc $ARGV[2] eq "TODAY" ) {

						$selectedDate1 = getFormatedTodaysDate();

					}
					else {

						$selectedDate1 =
						  Time::Piece->strptime( $ARGV[2], "%Y-%m-%d" )
						  ;    # just validate by conversion to a time piece
						$selectedDate1 = $ARGV[2];

					}

					if ( uc $ARGV[4] eq "TODAY" ) {

						$selectedDate2 = getFormatedTodaysDate();

					}
					else {

						$selectedDate2 =
						  Time::Piece->strptime( $ARGV[4], "%Y-%m-%d" )
						  ;    # just validate by conversion to a time piece
						$selectedDate2 = $ARGV[4];

					}

					$selectedDate1Offset = $ARGV[3];
					$selectedDate2Offset = $ARGV[5];
					$appMode             = 1;
					$invalidCommandLine  = 0;

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
	
USAGE:		perl get-data.pl <SUMMARY|REPORT>
	

SUMMARY NUMBEROFITEMERRORSFORPERIOD <TODAY|startDate(yyyy-mm-dd)> <startDateOffset> <TODAY|endDate(yyyy-mm-dd)> <endDateOffset> 		- Gets a number of item failures encountered for specified period. An 'item failure' is a failure on one file that was to be backed up. StartDateOffset and endDateOffset allow to shift each boundary date by the number of days. For example "SUMMARY NUMBEROFITEMERRORSFORPERIOD TODAY -6 TODAY 0 " returns number of item failures recorded in last seven days. 

SUMMARY NUMBEROFCLIENTERRORSFORPERIOD <TODAY|startDate(yyyy-mm-dd)> <startDateOffset> <TODAY|endDate(yyyy-mm-dd)> <endDateOffset> [dropboxId]		- Gets a number of client errors encountered for specified period. A 'client failure' is a failure of one backup job (i.e. unique client+subclient content). StartDateOffset and endDateOffset allow to shift each boundary date by the number of days. If dropboxId is specified, will store result to TA_DROPBOX under that dropboxId. For example "SUMMARY NUMBEROFCLIENTERRORSFORPERIOD TODAY -6 TODAY 0 T1KK3" returns number of client failures recorded in last seven days and stores it in TA_DROPBOX under T1KK3. 

SUMMARY NUMBEROFCLIENTERRORSXCONSECUTIVEDAYSFROMDAY <TODAY|date(yyyy-mm-dd)> <dateOffset> <numberOfConsecutiveAttempts> [dropboxId]		- Gets a number of clients that failed for the specified number of most recent consecutive backup attempts backwards from the specified date. A 'client failure' is a failure of one backup job (i.e. unique client+subclient content). StartDateOffset and endDateOffset allow to shift each boundary date by the number of days. If dropboxId is specified, will store result to TA_DROPBOX under that dropboxId. For example "SUMMARY NUMBEROFCLIENTERRORSXCONSECUTIVEDAYSFROMDAY TODAY 0 3 C93V1" returns number of clients with 3 consecutive failures as of today and stores it in TA_DROPBOX under C93V1.


REPORT DASHBOARD "<TODAY|startDate(yyyy-mm-dd)>,<startDateOffset>,<TODAY|endDate(yyyy-mm-dd)>,<endDateOffset>,<displayOveralInfo>,<displayClientErrorInfo>,<4 ClientErrorInfo parameters>,<displayXConsecutiveClientErrorInfo>,<3 XConsecutiveClientErrorInfo parameters> [dropboxId]"		- Returns a simple HTML formatted dashboard, listing the status information of the reports imported in the specified period + some extra configurable sections. StartDateOffset and endDateOffset allows to shift each boundary date by the number of days. DisplayOveralInfo (0,1) : when 1, includes overall status section in the dashboard. DisplayClientErrorInfo (0,1) : when 1, includes client error info in the dashboard (the following 4 ClientErrorInfo parameters are same as for "REPORT DETAILEDCLIENTERRORSFORPERIOD"). DisplayXConsecutiveClientErrorInfo (0,1) : when 1, includes client error info in the dashboard (the following 3 XConsecutiveClientErrorInfo parameters are same as for "REPORT DETAILEDCLIENTERRORSXCONSECUTIVEDAYSFROMDAY"). If dropboxId is specified, will store result to TA_DROPBOX under that dropboxId. Valid parameters example: REPORT DASHBOARD "TODAY,0,TODAY,0,1,1,TODAY,0,TODAY,0,1,TODAY,0,3,4RE1T"  


REPORT DETAILEDCLIENTERRORSFORPERIOD <TODAY|startDate(yyyy-mm-dd)> <startDateOffset> <TODAY|endDate(yyyy-mm-dd)> <endDateOffset>		- Returns 'none' or a simple HTML formatted structured list of client failures in the selected period. A 'client failure' is a failure of one backup job (i.e. unique client+sublient content). StartDateOffset and endDateOffset allows to shift each boundary date by the number of days. For example "REPORT DETAILEDSTATUSFORPERIOD TODAY -6 TODAY 0" list client failures recorded in last seven days. 

REPORT DETAILEDCLIENTERRORSXCONSECUTIVEDAYSFROMDAY <TODAY|date(yyyy-mm-dd)> <dateOffset> <numberOfConsecutiveAttempts>		- Returns 'none' or a simple HTML formatted structured list of clients that failed for the specified number of most recent consecutive backup attempts backwards from the specified date. A 'client failure' is a failure of one backup job (i.e. unique client+sublient content). DateOffset allows to shift the date by the number of days. For example "REPORT DETAILEDCLIENTERRORSXCONSECUTIVEDAYSFROMDAY TODAY 0 3" list client that failed in last 3 consecutive backup attempts from today. 



	
LOGGING:	set \$loggingLevel variable : 0 - no logging, 1 - log errors only, 2 - log everything (errors, warnings, debug info)

		set \$logOutput variable : 1 - output to console, 2 - output to log file, 3 - output to both console and log file

NOTE:		do not use characters " _ ' in the command line
	
USAGELABEL

	exit 0;
}

## main execution block

given ($appMode) {

	when (1) {
		fnGetNumberOfItemErrorsForPeriod();
	}

	when (2) {
		fnMetadataScriptLogFileErrors();
	}

	when (3) {
		my $returnValue = getNumberOfClientErrorsVersatile();

		if ( defined($currentDropboxId) ) {

			writeValueToDropbox1( $currentDropboxId, $returnValue )

		}
		else {
			print $returnValue;
		}

		logEvent( 1, "Response : $returnValue" );

	}

	when (4) {
		fnMetadataImportProcedureLock();
	}

	when (5) {
		fnReportDashboardInHTML();
	}

	when (6) {

		my $returnValue;
		my $tmp1 = getReportDetailedClientErrorsForPeriodInHTML();

		if ( $tmp1 ne "none" ) {
			if ( $rdcefpSelectedDate1 eq $rdcefpSelectedDate2 ) {
				$returnValue =
				  "<b>CLIENT FAILURES ON $rdcefpSelectedDate1</b><br>";
			}
			else {
				$returnValue =
"<b>CLIENT FAILURES BETWEEN $rdcefpSelectedDate1 AND $rdcefpSelectedDate2</b><br>";
			}

			$returnValue .= $tmp1;

		}
		else {
			$returnValue = $tmp1;

		}

		print $returnValue;
		logEvent( 1, "Response : $returnValue" );

	}

	when (7) {
		fnReportDetailedClientErrorsForXConsecutiveDaysFromDayInHTML();
	}

	when (8) {

		my $returnValue = getDatabaseCachingStatus();
		print $returnValue;
		logEvent( 1, "Response : $returnValue" );

	}

	when (9) {
		my $returnValue = getNumberOfClientErrorsForXConsecutiveDaysFromDay();

		if ( defined($currentDropboxId) ) {

			writeValueToDropbox1( $currentDropboxId, $returnValue )

		}
		else {
			print $returnValue;
		}

		logEvent( 1, "Response : $returnValue" );

	}

}

logEvent( 1, "Finished" );

## end - main execution block

##  program exit point	###########################################################################

sub getFormatedTodaysDate {
	my (
		$second,     $minute,    $hour,
		$dayOfMonth, $month,     $year,
		$dayOfWeek,  $dayOfYear, $daylightSavings
	  )
	  = localtime();
	$year = $year + 1900;
	$month++;
	$month =
	  sprintf( "%02d", $month )
	  ;    # just align with zeroes from the left to conform mm
	$dayOfMonth =
	  sprintf( "%02d", $dayOfMonth )
	  ;    # just align with zeroes from the left to conform dd

	return "$year-$month-$dayOfMonth";

}

sub fnReportDetailedClientErrorsForXConsecutiveDaysFromDayInHTML {

	my $errorCounter = 0;
	my $returnValue;
	my $sth1;
	my $sth2;
	my $sql1;
	my $sql2;
	my $currentNavigationString;
	my $lastNavigationString;

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

		$rdcefcSelectedDate1 =
		  addDayOffsetToFormattedDateString( $rdcefcSelectedDate1,
			$rdcefcSelectedDate1Offset );

		logEvent( 1, "selectedDate1: $rdcefcSelectedDate1" );

		logEvent( 1, "consecutiveDaysNumber: $consecutiveDaysNumber" );

		$sql1 = <<DELIMITER1;
		
-- STATEMENT EXPLANATION:                
-- Purpose: Retrieves failed client tasks for the specified day that have failed consecutively in n1 previous occurences (regardless on error number). Applies error exceptions/templates.
-- Outer Query O "SELECT A.DL_CLIENT_ID,..." : lists all failed tasks for specified day but keeps only those which comply to "not exists" condition of nested query A and "equals condition" of nested query B and "not exists" of nested query OE
-- 	Nested Query A "NOT EXISTS ( SELECT 1 FROM TA_JOBS E,..." : helps the outer query to retrieve only most recent task record for the selected day (and relevant client and subclient content) that failed
-- 	 Double Nested Query AE "AND NOT EXISTS ( SELECT 1 FROM TA_CEEXCEPTIONS G,... " : applies client error exceptions/templates on parent query A
-- 	Nested Query B (named Nested2) "SELECT COUNT( 1 )FROM ( SELECT C.DL_CLIENT_ID,..." : helps the outer query to verify whether for the given outer query task record there are other two nearest relevant nearest task records that failed consecutively. How: in its own nested query, it will select the previous n-1 relevant rows (regardless if they have error or not) and then from the returned recordset, it will count how many of them have error and compares their count to the expected count - this is how it will find out if errors are consecutive
-- 	 Double Nested Query BE "AND NOT EXISTS ( SELECT 1 FROM TA_CEEXCEPTIONS G,... " : applies client error exceptions/templates on parent query B
--  Nested Query OE "AND NOT EXISTS ( SELECT 1 FROM TA_CEEXCEPTIONS G,... " : applies client error exceptions/templates on parent query O
SELECT A.DL_CLIENT_ID,
       A.DS_SUBCLIENT_CONTENT,
       A.DL_ID AS JOBID,
       D.DS_NAME AS CLIENTNAME
  FROM TA_JOBS A, 
       TA_REPORTS B, 
       TA_CLIENTS D
 WHERE A.DL_REPORT_ID = B.DL_ID 
       AND
       A.DL_CLIENT_ID = D.DL_ID 
       AND
       A.DS_FAILURE_ERROR_CODE <> '0' 
       AND
       NOT EXISTS ( 
           SELECT 1
             FROM TA_JOBS E, 
                  TA_REPORTS F
            WHERE E.DL_ID > A.DL_ID 
                  AND
                  E.DL_REPORT_ID = F.DL_ID 
                  AND
                  E.DL_CLIENT_ID = A.DL_CLIENT_ID 
                  AND
                  E.DS_SUBCLIENT_CONTENT = A.DS_SUBCLIENT_CONTENT 
                  AND
                  strftime( '%Y-%m-%d', F.DT_IMPORT_FINISHED ) = strftime( '%Y-%m-%d', 'param1' ) 
                  AND
                  E.DS_FAILURE_ERROR_CODE <> '0' 
                  AND
                  NOT EXISTS ( 
                      SELECT 1
                        FROM TA_CEEXCEPTIONS J, 
                             TA_CEEXCEPTION_TEMPLATES K, 
                             TA_CEEXCEPTION_TEMPLATES_MATCHING L
                       WHERE J.DL_EXCEPTION_TEMPLATE_ID = K.DL_ID 
                             AND
                             K.DL_ID = L.DL_EXCEPTION_TEMPLATE_ID 
                             AND
                             L.DL_CLIENT_ID = E.DL_CLIENT_ID 
                             AND
                             J.DS_ERROR_CODE = E.DS_FAILURE_ERROR_CODE 
                  ) 
                   
       ) 
       
       AND
       strftime( '%Y-%m-%d', B.DT_IMPORT_FINISHED ) = strftime( '%Y-%m-%d', 'param1' ) 
       AND
       ( 
           SELECT COUNT( 1 )
             FROM ( 
                   SELECT C.DL_CLIENT_ID,
                          C.DS_SUBCLIENT_CONTENT,
                          C.DS_FAILURE_ERROR_CODE
                     FROM TA_JOBS C
                    WHERE C.DL_CLIENT_ID = A.DL_CLIENT_ID 
                          AND
                          C.DL_ID < A.DL_ID 
                          AND
                          C.DS_SUBCLIENT_CONTENT = A.DS_SUBCLIENT_CONTENT 
                          AND
                          NOT EXISTS ( 
                              SELECT 1
                                FROM TA_CEEXCEPTIONS M, 
                                     TA_CEEXCEPTION_TEMPLATES N, 
                                     TA_CEEXCEPTION_TEMPLATES_MATCHING O
                               WHERE M.DL_EXCEPTION_TEMPLATE_ID = N.DL_ID 
                                     AND
                                     N.DL_ID = O.DL_EXCEPTION_TEMPLATE_ID 
                                     AND
                                     O.DL_CLIENT_ID = C.DL_CLIENT_ID 
                                     AND
                                     M.DS_ERROR_CODE = C.DS_FAILURE_ERROR_CODE 
                          ) 
                          
                    ORDER BY C.DL_ID DESC
                    LIMIT param2 - 1 
               ) 
               NESTED2
            WHERE NESTED2.DS_FAILURE_ERROR_CODE <> '0' 
       ) 
       = param2 - 1 
       AND
       NOT EXISTS ( 
           SELECT 1
             FROM TA_CEEXCEPTIONS G, 
                  TA_CEEXCEPTION_TEMPLATES H, 
                  TA_CEEXCEPTION_TEMPLATES_MATCHING I
            WHERE G.DL_EXCEPTION_TEMPLATE_ID = H.DL_ID 
                  AND
                  H.DL_ID = I.DL_EXCEPTION_TEMPLATE_ID 
                  AND
                  I.DL_CLIENT_ID = A.DL_CLIENT_ID 
                  AND
                  G.DS_ERROR_CODE = A.DS_FAILURE_ERROR_CODE 
       ) 
       
 ORDER BY A.DL_CLIENT_ID,
           A.DS_SUBCLIENT_CONTENT;

DELIMITER1

		$sql1 =~ s/param1/$rdcefcSelectedDate1/g
		  ; # parameters in complex parametrized sqlite queries do not work well. we do parameter replacement ourselves

		$sql1 =~ s/param2/$consecutiveDaysNumber/g
		  ; # parameters in complex parametrized sqlite queries do not work well. we do parameter replacement ourselves

		$sth1 = $slowDBH->prepare($sql1);
		$sth1->execute();

		my @rowArray1;

		while ( @rowArray1 = $sth1->fetchrow_array() ) {

			$currentNavigationString =
"<br><b>clientId @rowArray1[0] \"@rowArray1[3]\" , Subclient Content \"@rowArray1[1]\"</b><br>";
			$returnValue .= $currentNavigationString;

			$sql2 = <<DELIMITER1;
		
-- STATEMENT EXPLANATION:                
-- Purpose: Retrieves detail on consequential n relevant errorneous tasks that happened in the time before the recorded DL_ID, given from the above query. Applies error exceptions/templates.   
--  Nested Query E "AND NOT EXISTS ( SELECT 1 FROM TA_CEEXCEPTIONS G,... " : applies client error exceptions/templates on outer query
			
SELECT A.DL_ID,
       A.DS_JOBID,
       B.DL_ID,
       B.DT_IMPORT_FINISHED,
       A.DS_FAILURE_ERROR_CODE,
       A.DS_FAILURE_REASON
  FROM TA_JOBS A, 
       TA_REPORTS B, 
       TA_CLIENTS C
 WHERE A.DL_REPORT_ID = B.DL_ID 
       AND
       A.DL_CLIENT_ID = C.DL_ID 
       AND
       A.DS_FAILURE_ERROR_CODE <> '0' 
       AND
       A.DL_ID <= ? 
       AND
       A.DL_CLIENT_ID = ? 
       AND
       A.DS_SUBCLIENT_CONTENT = ? 
       AND
       NOT EXISTS ( 
           SELECT 1
             FROM TA_CEEXCEPTIONS D, 
                  TA_CEEXCEPTION_TEMPLATES E, 
                  TA_CEEXCEPTION_TEMPLATES_MATCHING F
            WHERE D.DL_EXCEPTION_TEMPLATE_ID = E.DL_ID 
                  AND
                  E.DL_ID = F.DL_EXCEPTION_TEMPLATE_ID 
                  AND
                  F.DL_CLIENT_ID = A.DL_CLIENT_ID 
                  AND
                  D.DS_ERROR_CODE = A.DS_FAILURE_ERROR_CODE 
       ) 
       
 ORDER BY A.DL_ID DESC
 LIMIT ( ? );

DELIMITER1

			$sth2 = $slowDBH->prepare($sql2);
			$sth2->execute(
				@rowArray1[2], @rowArray1[0],
				@rowArray1[1], $consecutiveDaysNumber
			);

			my @rowArray2;

			while ( @rowArray2 = $sth2->fetchrow_array() ) {

				$returnValue .=
"&nbsp;jobId @rowArray2[0] (Commcell JobId \"@rowArray2[1]\"; reportId @rowArray2[2]; report imported on @rowArray2[3]) : Failure Reason \"@rowArray2[5]\"<br>";

			}

		}

	};
	if ($@) {

		logEvent( 2,
"Error 1 occured in fnReportDetailedClientErrorsForXConsecutiveDaysFromDayInHTML(): $@"
		);

	}

	if ( defined($returnValue) ) {
		$returnValue =
"<b>CLIENTS WITH $consecutiveDaysNumber CONSECUTIVE FAILURES FROM $rdcefcSelectedDate1 BACKWARDS</b><br>"
		  . $returnValue;

		print $returnValue;
	}
	else {
		print "none";

	}

	logEvent( 1, "Response : $returnValue" );

}

sub getNumberOfClientErrorsForXConsecutiveDaysFromDay {

	my $errorCounter = 0;
	my $returnValue;
	my $sth1;
	my $sth2;
	my $sql1;
	my $sql2;
	my $currentNavigationString;
	my $lastNavigationString;

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

		$rdcefcSelectedDate1 =
		  addDayOffsetToFormattedDateString( $rdcefcSelectedDate1,
			$rdcefcSelectedDate1Offset );

		logEvent( 1, "selectedDate1: $rdcefcSelectedDate1" );

		logEvent( 1, "consecutiveDaysNumber: $consecutiveDaysNumber" );

		$sql1 = <<DELIMITER1;
		
-- STATEMENT EXPLANATION:                
-- Purpose: Retrieves failed client tasks for the specified day that have failed consecutively in n1 previous occurences (regardless on error number). Applies error exceptions/templates.
-- Outer Query O "SELECT A.DL_CLIENT_ID,..." : lists all failed tasks for specified day but keeps only those which comply to "not exists" condition of nested query A and "equals condition" of nested query B and "not exists" of nested query OE
-- 	Nested Query A "NOT EXISTS ( SELECT 1 FROM TA_JOBS E,..." : helps the outer query to retrieve only most recent task record for the selected day (and relevant client and subclient content) that failed
-- 	 Double Nested Query AE "AND NOT EXISTS ( SELECT 1 FROM TA_CEEXCEPTIONS G,... " : applies client error exceptions/templates on parent query A
-- 	Nested Query B (named Nested2) "SELECT COUNT( 1 )FROM ( SELECT C.DL_CLIENT_ID,..." : helps the outer query to verify whether for the given outer query task record there are other two nearest relevant nearest task records that failed consecutively. How: in its own nested query, it will select the previous n-1 relevant rows (regardless if they have error or not) and then from the returned recordset, it will count how many of them have error and compares their count to the expected count - this is how it will find out if errors are consecutive
-- 	 Double Nested Query BE "AND NOT EXISTS ( SELECT 1 FROM TA_CEEXCEPTIONS G,... " : applies client error exceptions/templates on parent query B
--  Nested Query OE "AND NOT EXISTS ( SELECT 1 FROM TA_CEEXCEPTIONS G,... " : applies client error exceptions/templates on parent query O

SELECT COUNT(1) FROM
(
SELECT A.DL_CLIENT_ID,
       A.DS_SUBCLIENT_CONTENT,
       A.DL_ID AS JOBID,
       D.DS_NAME AS CLIENTNAME
  FROM TA_JOBS A, 
       TA_REPORTS B, 
       TA_CLIENTS D
 WHERE A.DL_REPORT_ID = B.DL_ID 
       AND
       A.DL_CLIENT_ID = D.DL_ID 
       AND
       A.DS_FAILURE_ERROR_CODE <> '0' 
       AND
       NOT EXISTS ( 
           SELECT 1
             FROM TA_JOBS E, 
                  TA_REPORTS F
            WHERE E.DL_ID > A.DL_ID 
                  AND
                  E.DL_REPORT_ID = F.DL_ID 
                  AND
                  E.DL_CLIENT_ID = A.DL_CLIENT_ID 
                  AND
                  E.DS_SUBCLIENT_CONTENT = A.DS_SUBCLIENT_CONTENT 
                  AND
                  strftime( '%Y-%m-%d', F.DT_IMPORT_FINISHED ) = strftime( '%Y-%m-%d', 'param1' ) 
                  AND
                  E.DS_FAILURE_ERROR_CODE <> '0' 
                  AND
                  NOT EXISTS ( 
                      SELECT 1
                        FROM TA_CEEXCEPTIONS J, 
                             TA_CEEXCEPTION_TEMPLATES K, 
                             TA_CEEXCEPTION_TEMPLATES_MATCHING L
                       WHERE J.DL_EXCEPTION_TEMPLATE_ID = K.DL_ID 
                             AND
                             K.DL_ID = L.DL_EXCEPTION_TEMPLATE_ID 
                             AND
                             L.DL_CLIENT_ID = E.DL_CLIENT_ID 
                             AND
                             J.DS_ERROR_CODE = E.DS_FAILURE_ERROR_CODE 
                  ) 
                   
       ) 
       
       AND
       strftime( '%Y-%m-%d', B.DT_IMPORT_FINISHED ) = strftime( '%Y-%m-%d', 'param1' ) 
       AND
       ( 
           SELECT COUNT( 1 )
             FROM ( 
                   SELECT C.DL_CLIENT_ID,
                          C.DS_SUBCLIENT_CONTENT,
                          C.DS_FAILURE_ERROR_CODE
                     FROM TA_JOBS C
                    WHERE C.DL_CLIENT_ID = A.DL_CLIENT_ID 
                          AND
                          C.DL_ID < A.DL_ID 
                          AND
                          C.DS_SUBCLIENT_CONTENT = A.DS_SUBCLIENT_CONTENT 
                          AND
                          NOT EXISTS ( 
                              SELECT 1
                                FROM TA_CEEXCEPTIONS M, 
                                     TA_CEEXCEPTION_TEMPLATES N, 
                                     TA_CEEXCEPTION_TEMPLATES_MATCHING O
                               WHERE M.DL_EXCEPTION_TEMPLATE_ID = N.DL_ID 
                                     AND
                                     N.DL_ID = O.DL_EXCEPTION_TEMPLATE_ID 
                                     AND
                                     O.DL_CLIENT_ID = C.DL_CLIENT_ID 
                                     AND
                                     M.DS_ERROR_CODE = C.DS_FAILURE_ERROR_CODE 
                          ) 
                          
                    ORDER BY C.DL_ID DESC
                    LIMIT param2 - 1 
               ) 
               NESTED2
            WHERE NESTED2.DS_FAILURE_ERROR_CODE <> '0' 
       ) 
       = param2 - 1 
       AND
       NOT EXISTS ( 
           SELECT 1
             FROM TA_CEEXCEPTIONS G, 
                  TA_CEEXCEPTION_TEMPLATES H, 
                  TA_CEEXCEPTION_TEMPLATES_MATCHING I
            WHERE G.DL_EXCEPTION_TEMPLATE_ID = H.DL_ID 
                  AND
                  H.DL_ID = I.DL_EXCEPTION_TEMPLATE_ID 
                  AND
                  I.DL_CLIENT_ID = A.DL_CLIENT_ID 
                  AND
                  G.DS_ERROR_CODE = A.DS_FAILURE_ERROR_CODE 
       ) 
       
 ORDER BY A.DL_CLIENT_ID,
           A.DS_SUBCLIENT_CONTENT
)

DELIMITER1

		$sql1 =~ s/param1/$rdcefcSelectedDate1/g
		  ; # parameters in complex parametrized sqlite queries do not work well. we do parameter replacement ourselves

		$sql1 =~ s/param2/$consecutiveDaysNumber/g
		  ; # parameters in complex parametrized sqlite queries do not work well. we do parameter replacement ourselves

		$sth1 = $slowDBH->prepare($sql1);
		$sth1->execute();

		my @rowArray1;

		@rowArray1   = $sth1->fetchrow_array();
		$returnValue = @rowArray1[0];

	};
	if ($@) {

		logEvent( 2,
"Error 1 occured in fnReportDetailedClientErrorsForXConsecutiveDaysFromDayInHTML(): $@"
		);

	}

	return $returnValue;

}

sub getNumberOfClientErrorsForPeriod {

	my $errorCounter = 0;
	my $returnValue  = -1;
	my $sth;
	my $sql1;
	my $currentNavigationString1;
	my $lastNavigationString1;
	my $currentNavigationString2;
	my $lastNavigationString2;

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

		$rdcefpSelectedDate1 =
		  addDayOffsetToFormattedDateString( $rdcefpSelectedDate1,
			$rdcefpSelectedDate1Offset );
		$rdcefpSelectedDate2 =
		  addDayOffsetToFormattedDateString( $rdcefpSelectedDate2,
			$rdcefpSelectedDate2Offset );

		logEvent( 1, "selectedDate1: $rdcefpSelectedDate1" );
		logEvent( 1, "selectedDate2: $rdcefpSelectedDate2" );

		$sql1 = <<DELIMITER1;
SELECT COUNT(1) FROM
(		
SELECT A.DS_FAILURE_REASON,
       C.DS_NAME,
       C.DL_ID,
       A.DS_SUBCLIENT_CONTENT,
       A.DL_ID,
       A.DS_JOBID,
       B.DL_ID,
       B.DT_IMPORT_FINISHED,
       A.DS_FAILURE_ERROR_CODE
  FROM TA_JOBS A, 
       TA_REPORTS B, 
       TA_CLIENTS C
 WHERE A.DL_REPORT_ID = B.DL_ID 
       AND
       A.DL_CLIENT_ID = C.DL_ID 
       AND
       A.DS_FAILURE_ERROR_CODE <> '0' 
       AND
       NOT EXISTS ( 
           SELECT 1
             FROM TA_CEEXCEPTIONS D, 
                  TA_CEEXCEPTION_TEMPLATES E, 
                  TA_CEEXCEPTION_TEMPLATES_MATCHING F
            WHERE D.DL_EXCEPTION_TEMPLATE_ID = E.DL_ID 
                  AND
                  E.DL_ID = F.DL_EXCEPTION_TEMPLATE_ID 
                  AND
                  F.DL_CLIENT_ID = A.DL_CLIENT_ID 
                  AND
                  D.DS_ERROR_CODE = A.DS_FAILURE_ERROR_CODE 
       ) 
       
       AND
       ( B.DT_IMPORT_FINISHED IS NOT NULL ) 
       AND
       ( strftime( '%Y-%m-%d', B.DT_IMPORT_FINISHED ) BETWEEN strftime( '%Y-%m-%d', ? )  AND strftime( '%Y-%m-%d', ? )  ) 
 ORDER BY A.DL_CLIENT_ID
 ) NESTED1;

DELIMITER1

		$sth = $slowDBH->prepare($sql1);

		$sth->execute( $rdcefpSelectedDate1, $rdcefpSelectedDate2 );

		my @rowArray = $sth->fetchrow_array();
		$returnValue = @rowArray[0];

	};
	if ($@) {

		logEvent( 2, "Error 1 occured in fnSummaryNumberOfClientErrors(): $@" );

	}

	return $returnValue;

}

sub getReportDetailedClientErrorsForPeriodInHTML {

	my $errorCounter = 0;
	my $returnValue  = "none";
	my $sth;
	my $sql1;
	my $currentNavigationString1;
	my $lastNavigationString1;
	my $currentNavigationString2;
	my $lastNavigationString2;

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

		$rdcefpSelectedDate1 =
		  addDayOffsetToFormattedDateString( $rdcefpSelectedDate1,
			$rdcefpSelectedDate1Offset );
		$rdcefpSelectedDate2 =
		  addDayOffsetToFormattedDateString( $rdcefpSelectedDate2,
			$rdcefpSelectedDate2Offset );

		logEvent( 1, "selectedDate1: $rdcefpSelectedDate1" );
		logEvent( 1, "selectedDate2: $rdcefpSelectedDate2" );

		$sql1 = <<DELIMITER1;
		
SELECT A.DS_FAILURE_REASON,
       C.DS_NAME,
       C.DL_ID,
       A.DS_SUBCLIENT_CONTENT,
       A.DL_ID,
       A.DS_JOBID,
       B.DL_ID,
       B.DT_IMPORT_FINISHED,
       A.DS_FAILURE_ERROR_CODE
  FROM TA_JOBS A, 
       TA_REPORTS B, 
       TA_CLIENTS C
 WHERE A.DL_REPORT_ID = B.DL_ID 
       AND
       A.DL_CLIENT_ID = C.DL_ID 
       AND
       A.DS_FAILURE_ERROR_CODE <> '0' 
       AND
       NOT EXISTS ( 
           SELECT 1
             FROM TA_CEEXCEPTIONS D, 
                  TA_CEEXCEPTION_TEMPLATES E, 
                  TA_CEEXCEPTION_TEMPLATES_MATCHING F
            WHERE D.DL_EXCEPTION_TEMPLATE_ID = E.DL_ID 
                  AND
                  E.DL_ID = F.DL_EXCEPTION_TEMPLATE_ID 
                  AND
                  F.DL_CLIENT_ID = A.DL_CLIENT_ID 
                  AND
                  D.DS_ERROR_CODE = A.DS_FAILURE_ERROR_CODE 
       ) 
       
       AND
       ( B.DT_IMPORT_FINISHED IS NOT NULL ) 
       AND
       ( strftime( '%Y-%m-%d', B.DT_IMPORT_FINISHED ) BETWEEN strftime( '%Y-%m-%d', ? )  AND strftime( '%Y-%m-%d', ? )  ) 
 ORDER BY A.DL_CLIENT_ID;

DELIMITER1

		$sth = $slowDBH->prepare($sql1);

		$sth->execute( $rdcefpSelectedDate1, $rdcefpSelectedDate2 );

		my @rowArray;
		my $rowCounter = 1;

		while ( @rowArray = $sth->fetchrow_array() ) {

			if ( $rowCounter == 1 ) {
				$returnValue = "";
			}

			$currentNavigationString1 =
			  "<br><b>clientId @rowArray[2] \"@rowArray[1]\"</b><br>";
			if ( $currentNavigationString1 ne $lastNavigationString1 ) {
				$returnValue .= $currentNavigationString1;
				$lastNavigationString2 = "";
			}

			$currentNavigationString2 =
			  "<b>&nbsp;Subclient Content \"@rowArray[3]\"</b><br>";
			if ( $currentNavigationString2 ne $lastNavigationString2 ) {
				$returnValue .= $currentNavigationString2;
			}

			$returnValue .=
"&nbsp;&nbsp;jobId @rowArray[4] (Commcell JobId \"@rowArray[5]\"; reportId @rowArray[6]; report imported on @rowArray[7]) : Failure Reason \"@rowArray[0]\"<br>";

			$rowCounter++;
			$lastNavigationString1 = $currentNavigationString1;
			$lastNavigationString2 = $currentNavigationString2;

		}

	};
	if ($@) {

		logEvent( 2, "Error 1 occured in fnSummaryNumberOfClientErrors(): $@" );

	}

	return $returnValue;

}

sub getNumberOfIgnoredClientErrorsVersatile {
	my ($reportId) = @_
	  ; # reportId is optional (this function is called from number of places with different requirements)

	my $errorCounter = 0;
	my $returnValue;
	my $sth;
	my $sql1;

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

		if ( defined($reportId) ) {   # we want result only for specified report

			$sql1 = <<DELIMITER1;
		
SELECT COUNT( 1 )
  FROM TA_JOBS A, 
       TA_REPORTS B
 WHERE A.DL_REPORT_ID = B.DL_ID 
       AND
       DS_FAILURE_ERROR_CODE <> '0'
       AND
       EXISTS ( 
           SELECT 1
             FROM TA_CEEXCEPTIONS D, 
                  TA_CEEXCEPTION_TEMPLATES E, 
                  TA_CEEXCEPTION_TEMPLATES_MATCHING F
            WHERE D.DL_EXCEPTION_TEMPLATE_ID = E.DL_ID 
                  AND
                  E.DL_ID = F.DL_EXCEPTION_TEMPLATE_ID 
                  AND
                  F.DL_CLIENT_ID = A.DL_CLIENT_ID 
                  AND
                  D.DS_ERROR_CODE = A.DS_FAILURE_ERROR_CODE 
       ) 
       AND
       B.DL_ID = ?;
       
DELIMITER1

			$sth = $slowDBH->prepare($sql1);

			$sth->execute($reportId);

		}
		else {

			$selectedDate1 =
			  addDayOffsetToFormattedDateString( $selectedDate1,
				$selectedDate1Offset );
			$selectedDate2 =
			  addDayOffsetToFormattedDateString( $selectedDate2,
				$selectedDate2Offset );

			logEvent( 1, "selectedDate1: $selectedDate1" );
			logEvent( 1, "selectedDate2: $selectedDate2" );

			$sql1 = <<DELIMITER1;
		
SELECT COUNT( 1 )
  FROM TA_JOBS A, 
       TA_REPORTS B
 WHERE A.DL_REPORT_ID = B.DL_ID 
       AND
       DS_FAILURE_ERROR_CODE <> '0' 
       AND
       ( B.DT_IMPORT_FINISHED IS NOT NULL )
       AND
       EXISTS ( 
           SELECT 1
             FROM TA_CEEXCEPTIONS D, 
                  TA_CEEXCEPTION_TEMPLATES E, 
                  TA_CEEXCEPTION_TEMPLATES_MATCHING F
            WHERE D.DL_EXCEPTION_TEMPLATE_ID = E.DL_ID 
                  AND
                  E.DL_ID = F.DL_EXCEPTION_TEMPLATE_ID 
                  AND
                  F.DL_CLIENT_ID = A.DL_CLIENT_ID 
                  AND
                  D.DS_ERROR_CODE = A.DS_FAILURE_ERROR_CODE 
       )  
       AND
       ( strftime( '%Y-%m-%d', B.DT_IMPORT_FINISHED ) BETWEEN strftime( '%Y-%m-%d', ? ) 
       AND
       strftime( '%Y-%m-%d', ? ));
       
DELIMITER1

			$sth = $slowDBH->prepare($sql1);

			$sth->execute( $selectedDate1, $selectedDate2 );

		}

		my $tmp1 = $sth->fetch();

		$sth->finish();   # end statement, release resources (not a transaction)

		$returnValue =
		  @$tmp1[0]
		  ; # dereference array referenced by $tmp1, retrieve its first item and store it in a scalar variable that is referenced by $value1

	};

	if ($@) {

		logEvent( 2, "Error 1 occured in fnSummaryNumberOfClientErrors(): $@" );

	}

	if ( defined($returnValue) ) {
		return $returnValue;
	}
	else {
		return 0;

	}

}

sub getNumberOfReadyForReviewBackupJobs {
	my ($reportId) = @_;

	my $errorCounter = 0;
	my $returnValue;
	my $sth;
	my $sql1;

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

		$sql1 = <<DELIMITER1;
		
SELECT COUNT( 1 )
  FROM TA_JOBS A, 
       TA_REPORTS B
 WHERE A.DL_REPORT_ID = B.DL_ID 
       AND
       B.DL_ID = ?;
       
DELIMITER1

		$sth = $slowDBH->prepare($sql1);

		$sth->execute($reportId);

		my $tmp1 = $sth->fetch();

		$sth->finish();   # end statement, release resources (not a transaction)

		$returnValue =
		  @$tmp1[0]
		  ; # dereference array referenced by $tmp1, retrieve its first item and store it in a scalar variable that is referenced by $value1

	};

	if ($@) {

		logEvent( 2,
			"Error 1 occured in getNumberOfReadyForReviewBackupJobs(): $@" );

	}

	if ( defined($returnValue) ) {
		return $returnValue;
	}
	else {
		return 0;

	}

}

sub getNumberOfClientErrorsVersatile {
	my ($reportId) = @_
	  ; # reportId is optional (this function is called from number of places with different requirements - for a specific reportid or not)

	my $errorCounter = 0;
	my $returnValue;
	my $sth;
	my $sql1;

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

		if ( defined($reportId) ) {   # we want result only for specified report

			$sql1 = <<DELIMITER1;
		
SELECT COUNT( 1 )
  FROM TA_JOBS A, 
       TA_REPORTS B
 WHERE A.DL_REPORT_ID = B.DL_ID 
       AND
       DS_FAILURE_ERROR_CODE <> '0'
       AND
       NOT EXISTS ( 
           SELECT 1
             FROM TA_CEEXCEPTIONS D, 
                  TA_CEEXCEPTION_TEMPLATES E, 
                  TA_CEEXCEPTION_TEMPLATES_MATCHING F
            WHERE D.DL_EXCEPTION_TEMPLATE_ID = E.DL_ID 
                  AND
                  E.DL_ID = F.DL_EXCEPTION_TEMPLATE_ID 
                  AND
                  F.DL_CLIENT_ID = A.DL_CLIENT_ID 
                  AND
                  D.DS_ERROR_CODE = A.DS_FAILURE_ERROR_CODE 
       ) 
       AND
       B.DL_ID = ?;
       
DELIMITER1

			$sth = $slowDBH->prepare($sql1);

			$sth->execute($reportId);

		}
		else {

			$selectedDate1 =
			  addDayOffsetToFormattedDateString( $selectedDate1,
				$selectedDate1Offset );
			$selectedDate2 =
			  addDayOffsetToFormattedDateString( $selectedDate2,
				$selectedDate2Offset );

			logEvent( 1, "selectedDate1: $selectedDate1" );
			logEvent( 1, "selectedDate2: $selectedDate2" );

			$sql1 = <<DELIMITER1;
		
SELECT COUNT( 1 )
  FROM TA_JOBS A, 
       TA_REPORTS B
 WHERE A.DL_REPORT_ID = B.DL_ID 
       AND
       DS_FAILURE_ERROR_CODE <> '0' 
       AND
       ( B.DT_IMPORT_FINISHED IS NOT NULL )
       AND
       NOT EXISTS ( 
           SELECT 1
             FROM TA_CEEXCEPTIONS D, 
                  TA_CEEXCEPTION_TEMPLATES E, 
                  TA_CEEXCEPTION_TEMPLATES_MATCHING F
            WHERE D.DL_EXCEPTION_TEMPLATE_ID = E.DL_ID 
                  AND
                  E.DL_ID = F.DL_EXCEPTION_TEMPLATE_ID 
                  AND
                  F.DL_CLIENT_ID = A.DL_CLIENT_ID 
                  AND
                  D.DS_ERROR_CODE = A.DS_FAILURE_ERROR_CODE 
       )  
       AND
       ( strftime( '%Y-%m-%d', B.DT_IMPORT_FINISHED ) BETWEEN strftime( '%Y-%m-%d', ? ) 
       AND
       strftime( '%Y-%m-%d', ? ));
       
DELIMITER1

			$sth = $slowDBH->prepare($sql1);

			$sth->execute( $selectedDate1, $selectedDate2 );

		}

		my $tmp1 = $sth->fetch();

		$sth->finish();   # end statement, release resources (not a transaction)

		$returnValue =
		  @$tmp1[0]
		  ; # dereference array referenced by $tmp1, retrieve its first item and store it in a scalar variable that is referenced by $value1

	};

	if ($@) {

		logEvent( 2, "Error 1 occured in fnSummaryNumberOfClientErrors(): $@" );

	}

	if ( defined($returnValue) ) {
		return $returnValue;
	}
	else {
		return 0;

	}

}

sub fnGetNumberOfItemErrorsForPeriod {

	my $errorCounter = 0;

	$selectedDate1 =
	  addDayOffsetToFormattedDateString( $selectedDate1, $selectedDate1Offset );
	$selectedDate2 =
	  addDayOffsetToFormattedDateString( $selectedDate2, $selectedDate2Offset );

	logEvent( 1, "selectedDate1: $selectedDate1" );
	logEvent( 1, "selectedDate2: $selectedDate2" );

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

SELECT DS_FILENAME,
       DT_IMPORT_STARTED,
       DL_ID
  FROM TA_REPORTS
 WHERE ( DT_IMPORT_FINISHED IS NOT NULL ) 
       AND
       ( strftime( '%Y-%m-%d', DT_IMPORT_FINISHED ) BETWEEN strftime( '%Y-%m-%d', ? ) AND strftime( '%Y-%m-%d', ? )  ) 
 ORDER BY DL_ID;

DELIMITER1

		my $sth = $slowDBH->prepare($sql1);

		$sth->execute( $selectedDate1, $selectedDate2 );

		my @rowArray;
		my $rowCounter = 1;

		while ( @rowArray = $sth->fetchrow_array() ) {

			my $itemProblemCount;
			my $itemDirectoriesProblemCount;

			my $ignoredItemProblemCount;
			my $ignoredItemDirectoriesProblemCount;

			my $error = evaluateReportProblems1(
				@rowArray[2],
				\$itemProblemCount,
				\$itemDirectoriesProblemCount,
				\$ignoredItemProblemCount,
				\$ignoredItemDirectoriesProblemCount
			);

#print
#"ReportId @rowArray[2] : \"@rowArray[0]\" imported on @rowArray[1], found $itemProblemCount problematic items in $itemDirectoriesProblemCount directories (ignored $ignoredItemProblemCount items in $ignoredItemDirectoriesProblemCount directories)\n\n";

			$errorCounter = $errorCounter + $itemProblemCount;

			$rowCounter++;

		}

		$sth->finish();   # end statement, release resources (not a transaction)
		$slowDBH->disconnect();

		$rowCounter--;

		#print("Listed $rowCounter reports.\n");

		$returnValue = $errorCounter;

	};

	if ($@) {
		logEvent( 2,
"Database error 1 in fnGetNumberOfItemErrorsForPeriod(): $DBI::errstr"
		);
		exit 1;
	}

	if ( defined($returnValue) ) {
		print "$returnValue";
	}
	else {
		print "0";

	}

	logEvent( 1, "Response : $returnValue" );

}

#
#sub fnMetadataImportProcedureLock {
#	my $dashboardGenerationProcedureLock;
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
#		readSettingFromDatabase1( "IMPORT_PROCEDURE_LOCK",
#			\$dashboardGenerationProcedureLock )
#		  or exit 1;
#
#		if ( !defined($dashboardGenerationProcedureLock) ) {
#			logEvent( 2,
#				"IMPORT_PROCEDURE_LOCK does not exist in TA_SETTINGS" );
#			exit 1;
#
#		}
#
#		$slowDBH->disconnect();
#
#	};
#
#	if ($@) {
#		logEvent( 2,
#			"Database error 1 in fnMetadataImportProcedureLock(): $DBI::errstr"
#		);
#		exit 1;
#	}
#
#	if ( defined($dashboardGenerationProcedureLock) ) {
#		print $dashboardGenerationProcedureLock;
#	}
#
#	logEvent( 1, "Response : $dashboardGenerationProcedureLock" );
#
#}

sub fnReportDashboardInHTML {
	my $overallStatusHTML                     = "";
	my $reportStatusHTML                      = "";
	my $clientErrorsForPeriodHTML             = "";
	my $clientXConsecutiveErrorsForPeriodHTML = "";
	my $databaseCachingStatusHTML             = "";
	my $anyErrorRecorded                      = 0;
	my $returnValue;
	my $cellBackgroundColor = "";
	my $phpServerAppURL;
	my $phpServerScriptName = "zscrdetail1.php";
	my $t0                  = gettimeofday() * 1000;
	my $defaultFontColor    = "white";

	logEvent( 1, "start1" );

	$selectedDate1 =
	  addDayOffsetToFormattedDateString( $selectedDate1, $selectedDate1Offset );
	$selectedDate2 =
	  addDayOffsetToFormattedDateString( $selectedDate2, $selectedDate2Offset );

	logEvent( 1, "selectedDate1: $selectedDate1" );
	logEvent( 1, "selectedDate2: $selectedDate2" );

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

		readSettingFromDatabase1( "WEB_APP_URL", \$phpServerAppURL )
		  or exit 1;

		if ( !defined($phpServerAppURL) ) {
			logEvent( 2, "WEB_APP_URL does not exist in TA_SETTINGS" );
			exit 1;

		}

	};

	if ($@) {
		logEvent( 2, "Error 1 in fnReportDashboardInHTML(): $@" );
		exit 1;
	}

	eval {

## Overall info generation

		if ($displayOverallInfo) {

			my $sql1 = <<DELIMITER1;
		
SELECT COUNT( 1 ),
       MIN( DT_IMPORT_FINISHED ),
       MAX( DT_IMPORT_FINISHED ),
       ( 
           SELECT COUNT( 1 )
            WHERE DT_IMPORT_FINISHED IS NULL 
       ) 
       AS UNFINISHEDCOUNT
  FROM TA_REPORTS;

       
DELIMITER1

			my $sth = $slowDBH->prepare($sql1);

			$sth->execute();

			my @rowArray = $sth->fetchrow_array();

			$sth->finish()
			  ;    # end statement, release resources (not a transaction)

			$databaseCachingStatusHTML = getDatabaseCachingStatus();
			if ( !( $databaseCachingStatusHTML =~ /OK -/ ) ) {
				$anyErrorRecorded = 1;
			}

			$overallStatusHTML .=
			  "<TABLE border=0 STYLE='color:" . $defaultFontColor . ";'>";
			$overallStatusHTML .= "<TR><TD style='text-align:left;'>";
			$overallStatusHTML .= "<b>OVERALL STATUS :</b><br>";

			$overallStatusHTML .=
"Database holds @rowArray[0] reports imported between @rowArray[1] and @rowArray[2]<br>";
			$overallStatusHTML .=
			  "Database file caching: $databaseCachingStatusHTML<br>";
			$overallStatusHTML .= "XXXSCHEDULER_STATUS_PLACEHOLDERXXX";
			$overallStatusHTML .= "</TD></TR>";
			$overallStatusHTML .= "</TABLE><br>";

		}

	};

	if ($@) {
		logEvent( 2, "Error 2 in fnReportDashboardInHTML(): $@" );
		exit 1;
	}

	eval {

## Report info generation

		my $sql1 = <<DELIMITER1;
		
SELECT DS_FILENAME,
       DT_IMPORT_STARTED,
       DL_ID,
       DT_IMPORT_FINISHED,
       ( strftime( '%s', DT_IMPORT_FINISHED ) - strftime( '%s', DT_IMPORT_STARTED )  ) AS ELAPSED_TIME
  FROM TA_REPORTS
 WHERE ( ( DT_IMPORT_FINISHED IS NULL ) 
           OR
       ( strftime( '%Y-%m-%d', DT_IMPORT_FINISHED ) BETWEEN strftime( '%Y-%m-%d', ? ) AND strftime( '%Y-%m-%d', ? )  )  ) 
 ORDER BY DL_ID;
       
DELIMITER1

		my $sth = $slowDBH->prepare($sql1);

		$sth->execute( $selectedDate1, $selectedDate2 );

		my @rowArray;
		my $rowCounter = 1;
		$cellBackgroundColor = "";

		if ( $selectedDate1 eq $selectedDate2 ) {
			$reportStatusHTML =
			  "<b>STATUS OF REPORTS IMPORTED ON $selectedDate1 :</b><br>";
		}
		else {
			$reportStatusHTML =
"<b>STATUS OF REPORTS IMPORTED BETWEEN $selectedDate1 AND $selectedDate2 :</b><br>";
		}

		$reportStatusHTML .=
		    "<table border=1 STYLE='color:"
		  . $defaultFontColor
		  . ";'><tr><th>ReportId</th><th>Import Status</th><th>Source Report File</th><th>Problems Detected</th><th>Errors Ignored</th></tr>";

		while ( @rowArray = $sth->fetchrow_array() ) {

			my $itemProblemCount;
			my $itemDirectoriesProblemCount;

			my $ignoredItemProblemCount;
			my $ignoredItemDirectoriesProblemCount;

			my $importStatus;
			my $elapsedTime;

			my $readyForReviewJobsCount =
			  getNumberOfReadyForReviewBackupJobs( @rowArray[2] );

			my $clientErrors = getNumberOfClientErrorsVersatile( @rowArray[2] );

			my $ignoredClientErrors =
			  getNumberOfIgnoredClientErrorsVersatile( @rowArray[2] );

			my $error = evaluateReportProblems1(
				@rowArray[2],
				\$itemProblemCount,
				\$itemDirectoriesProblemCount,
				\$ignoredItemProblemCount,
				\$ignoredItemDirectoriesProblemCount
			);

			$cellBackgroundColor = "";    # define the table row color
			if ( ( $itemProblemCount > 0 ) || ( $clientErrors > 0 ) ) {
				$cellBackgroundColor = "#FF9999";
				$anyErrorRecorded    = 1;
			}

			if ( !defined( @rowArray[3] ) ) {
				$importStatus = "IN PROGRESS <br> started on @rowArray[1]";
			}
			else {

				$elapsedTime = @rowArray[4];
				if ( $elapsedTime > 60 ) {
					$elapsedTime = ( $elapsedTime / 60 );
					$elapsedTime = sprintf( "%.2f", $elapsedTime );
					$elapsedTime .= " minutes";
				}
				else {
					$elapsedTime = sprintf( "%.2f", $elapsedTime );
					$elapsedTime .= " seconds";
				}

#				$importStatus =
#"COMPLETED <br>started on @rowArray[1]<br>finished on @rowArray[3]<br>took $elapsedTime<br>contains $readyForReviewJobsCount ready-for-review backup jobs";

				$importStatus =
"COMPLETED <br>import finished on @rowArray[3]<br>took $elapsedTime<br><a target='_blank' href='"
				  . $phpServerAppURL
				  . $phpServerScriptName
				  . "?a=9&rid="
				  . @rowArray[2]
				  . "'>$readyForReviewJobsCount ready-for-review backup jobs</a>";

			}

			$reportStatusHTML = $reportStatusHTML . "<tr>";

			$reportStatusHTML =
			  $reportStatusHTML
			  . "<th style='background-color:$cellBackgroundColor;'>@rowArray[2]</th>";

			$reportStatusHTML =
			  $reportStatusHTML
			  . "<th style='background-color:$cellBackgroundColor;'>$importStatus</th>";

			# format file path
			my $inputFileNameFormattedString = @rowArray[0];
			my $lastSlashCharacterIndex      = -1;
			for (
				my $loop = 0 ;
				$loop < length($inputFileNameFormattedString) ;
				$loop++
			  )
			{

				if (
					(
						substr( $inputFileNameFormattedString, $loop, 1 ) eq
						'\\'
					)
					|| (
						substr( $inputFileNameFormattedString, $loop, 1 ) eq
						'/' )
				  )
				{
					$lastSlashCharacterIndex = $loop;
				}

			}

#insert HTML break after the end of the path - so it doesn't take too much space in Zabbix screen
			if ( $lastSlashCharacterIndex > -1 ) {
				substr( $inputFileNameFormattedString,
					$lastSlashCharacterIndex + 1, 0 )
				  = '<br>';
			}

			$reportStatusHTML =
			  $reportStatusHTML
			  . "<th style='background-color:$cellBackgroundColor;'>$inputFileNameFormattedString</th>";

			$reportStatusHTML =
			    $reportStatusHTML
			  . "<th style='background-color:$cellBackgroundColor;'><a target='_blank' href='"
			  . $phpServerAppURL
			  . $phpServerScriptName
			  . "?a=1&rid="
			  . @rowArray[2]
			  . "'>$itemProblemCount items in $itemDirectoriesProblemCount directories</a>";

			$reportStatusHTML =
			    $reportStatusHTML
			  . "<br><a target='_blank' href='"
			  . $phpServerAppURL
			  . $phpServerScriptName
			  . "?a=4&rid="
			  . @rowArray[2]
			  . "'>$clientErrors client failures</a></th>";

			$reportStatusHTML =
			    $reportStatusHTML
			  . "<th style='background-color:$cellBackgroundColor;'><a target='_blank' href='"
			  . $phpServerAppURL
			  . $phpServerScriptName
			  . "?a=3&rid="
			  . @rowArray[2]
			  . "'>$ignoredItemProblemCount items in $ignoredItemDirectoriesProblemCount directories</a>";

			$reportStatusHTML =
			    $reportStatusHTML
			  . "<br><a target='_blank' href='"
			  . $phpServerAppURL
			  . $phpServerScriptName
			  . "?a=8&rid="
			  . @rowArray[2]
			  . "'>$ignoredClientErrors client failures</a></th>";

			$reportStatusHTML = $reportStatusHTML . "</tr>";

			$rowCounter++;

		}

		$reportStatusHTML .= "</table>";

		$sth->finish();   # end statement, release resources (not a transaction)
		$slowDBH->disconnect();

		$rowCounter--;

	};

	if ($@) {
		logEvent( 2, "Error 3 in fnReportDashboardInHTML(): $@" );
		exit 1;
	}

	eval {

## Client error in period info generation

		if ($displayClientErrorInfo) {

			my $tmp1 = getNumberOfClientErrorsForPeriod();
			my $tmp2;

			$cellBackgroundColor = "";

			if ( $tmp1 ne "0" ) {
				$anyErrorRecorded    = 1;
				$cellBackgroundColor = "#FF9999";
			}

			if ( $rdcefpSelectedDate1 eq $rdcefpSelectedDate2 ) {
				$tmp2 = "<b>CLIENT FAILURES ON $rdcefpSelectedDate1 :</b> ";
			}
			else {
				$tmp2 =
"<b>CLIENT FAILURES BETWEEN $rdcefpSelectedDate1 AND $rdcefpSelectedDate2 :</b> ";
			}

			$clientErrorsForPeriodHTML .= "<br>";
			$clientErrorsForPeriodHTML .= $tmp2;
			$clientErrorsForPeriodHTML .=
"<SPAN style='text-align:left;background-color:$cellBackgroundColor;white-space: nowrap;'>";

			if ( $tmp1 ne "0" ) {
				$clientErrorsForPeriodHTML .=
				    "<a target='_blank' href='"
				  . $phpServerAppURL
				  . $phpServerScriptName
				  . "?a=6&p0=$rdcefpSelectedDate1&p1=$rdcefpSelectedDate2'>";
			}

			$clientErrorsForPeriodHTML .= $tmp1;

			if ( $tmp1 ne "0" ) {
				$clientErrorsForPeriodHTML .= "</a>";
			}

			$clientErrorsForPeriodHTML .= "</SPAN><br>";

		}

	};

	if ($@) {
		logEvent( 2, "Error 4 in fnReportDashboardInHTML(): $@" );
		exit 1;
	}

	eval {

## X Consecutive client error in period info generation

		if ($displayXConsecutiveClientErrorInfo) {

			my $tmp1 = getNumberOfClientErrorsForXConsecutiveDaysFromDay();
			my $tmp2;

			$cellBackgroundColor = "";

			if ( $tmp1 ne "0" ) {
				$anyErrorRecorded    = 1;
				$cellBackgroundColor = "#FF9999";
			}

			$tmp2 =
"<b>CLIENTS WITH $consecutiveDaysNumber CONSECUTIVE FAILURES FROM THE LATEST RECORDED ON $rdcefcSelectedDate1 BACKWARDS :</b> ";

			$clientXConsecutiveErrorsForPeriodHTML .= "<br>";
			$clientXConsecutiveErrorsForPeriodHTML .= $tmp2;
			$clientXConsecutiveErrorsForPeriodHTML .=
"<SPAN style='text-align:left;background-color:$cellBackgroundColor;white-space: nowrap;'>";

			if ( $tmp1 ne "0" ) {
				$clientXConsecutiveErrorsForPeriodHTML .=
				    "<a target='_blank' href='"
				  . $phpServerAppURL
				  . $phpServerScriptName
				  . "?a=7&p0=$rdcefpSelectedDate1&cd=$consecutiveDaysNumber'>";
			}

			$clientXConsecutiveErrorsForPeriodHTML .= $tmp1;

			if ( $tmp1 ne "0" ) {
				$clientXConsecutiveErrorsForPeriodHTML .= "</a>";
			}

			$clientXConsecutiveErrorsForPeriodHTML .= "</SPAN><br>";

		}

	};

	if ($@) {
		logEvent( 2, "Error 5 in fnReportDashboardInHTML(): $@" );
		exit 1;
	}

## Putting it all together

	$cellBackgroundColor = "";
	if ($anyErrorRecorded) {
		$cellBackgroundColor = "#FF9999";
	}

	$returnValue .=
	    "<TABLE border=1 STYLE='color:"
	  . $defaultFontColor
	  . ";'><TR><TD style='background-color:$cellBackgroundColor;'>&nbsp;</TD><TD style='text-align:left;'>";

	if ($displayOverallInfo) {
		$returnValue .= $overallStatusHTML;
	}

	$returnValue .= $reportStatusHTML;

	if ($displayClientErrorInfo) {
		$returnValue .= $clientErrorsForPeriodHTML;
	}

	if ($displayXConsecutiveClientErrorInfo) {
		$returnValue .= $clientXConsecutiveErrorsForPeriodHTML;
	}

	my $t1 = gettimeofday() * 1000;

	my ( $s, $usec ) = gettimeofday();    # get microseconds haha
	my $timestamp = localtime->strftime("%Y-%m-%d %H:%M:%S");

	$returnValue .=
	    "<br>This report was completed on $timestamp and took "
	  . sprintf( "%.2f", ( ( $t1 - $t0 ) / 1000 ) )
	  . " seconds to generate";

	$returnValue .= "</TD></TR></TABLE>";

	$returnValue .=
	    "<div style='background-color:silver'> <a target='_blank' href='"
	  . $phpServerAppURL
	  . $phpServerScriptName
	  . "?a=12'>View Directory Item Error Exceptions</a>&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;";

	$returnValue .=
	    "<a target='_blank' href='"
	  . $phpServerAppURL
	  . $phpServerScriptName
	  . "?a=13'>View Client Error Exceptions</a></div>";

	if ( defined($currentDropboxId) ) {

		writeValueToDropbox1( $currentDropboxId, $returnValue )

	}
	else {
		print $returnValue;
	}

	logEvent( 1, "Response : $returnValue" );

	logEvent( 1, "end1" );

}

sub bytesToHuman {
	my $size_in_bytes = shift;

	if ( $size_in_bytes > ( 1024 * 1024 ) ) {

		return sprintf( "%.1f", ( $size_in_bytes / ( 1024 * 1024 ) ) ) . "MB";

	}
	else {

		return sprintf( "%.1f", ( $size_in_bytes / 1024 ) ) . "KB";

	}

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

sub isInteger {
	my $val = shift;
	return ( $val =~ /^[+-]?\d+$/ );
}

sub addDayOffsetToFormattedDateString {
	my ( $inDate, $dayOffset ) = @_;

	my $dt = Time::Piece->strptime( $inDate, '%Y-%m-%d' );
	$dt += ONE_DAY * $dayOffset;

	return $dt->strftime('%Y-%m-%d');
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

SELECT COUNT( 1 )
  FROM ( 
    SELECT A.DL_JOB_ID,
	B.DL_CLIENT_ID,
       A.DL_ITEM_PATH_ID,
       D.DS_DATA,
       C.DS_NAME,
       B.DS_SUBCLIENT_CONTENT,
       COUNT( 1 )
  FROM TA_JOB_ITEMS A, 
       TA_JOBS B, 
       TA_CLIENTS C, 
       TA_REDUNDANT_DATA_LOOKUP D
 WHERE A.DL_JOB_ID = B.DL_ID 
       AND
       B.DL_REPORT_ID = ? 
       AND
       B.DL_CLIENT_ID = C.DL_ID 
       AND
       A.DL_ITEM_PATH_ID = D.DL_ID 
       AND
       NOT EXISTS ( 
           SELECT 1
             FROM TA_DIEXCEPTIONS ZA, 
                  TA_DIEXCEPTION_TEMPLATES_MATCHING ZB, 
                  TA_REDUNDANT_DATA_LOOKUP ZC
            WHERE ZA.DL_EXCEPTION_TEMPLATE_ID = ZB.DL_EXCEPTION_TEMPLATE_ID 
                  AND
                  B.DL_CLIENT_ID = ZB.DL_CLIENT_ID 
                  AND
                  A.DL_ITEM_PATH_ID = ZC.DL_ID 
                  AND
                  ( ZC.DS_DATA LIKE ( ZA.DS_ITEM_PATH || '%' )  )  
       ) 
       
 GROUP BY A.DL_JOB_ID,
          A.DL_ITEM_PATH_ID
 ORDER BY A.DL_JOB_ID,
           A.DL_ITEM_PATH_ID
                     
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

	my $sql1 = <<DELIMITER1;
	
SELECT COUNT( 1 )
  FROM TA_JOB_ITEMS A, 
       TA_JOBS B
 WHERE A.DL_JOB_ID = B.DL_ID 
       AND
       B.DL_REPORT_ID = ?;
	
DELIMITER1

	$sth = $slowDBH->prepare($sql1);

	$sth->execute($reportId);

	$tmp1 = $sth->fetch();

	$sth->finish();    # end statement, release resources (not a transaction)

	$$ignoredItemProblemCount = @$tmp1[0] - $$itemProblemCount;

	# count directories which had problematic items, do not filter

	my $sql1 = <<DELIMITER1;

SELECT COUNT( 1 )
  FROM ( 
    SELECT A.DL_JOB_ID,
           B.DL_CLIENT_ID,
           A.DL_ITEM_PATH_ID,
           D.DS_DATA,
           C.DS_NAME,
           B.DS_SUBCLIENT_CONTENT,
           COUNT( 1 )
      FROM TA_JOB_ITEMS A, 
           TA_JOBS B, 
           TA_CLIENTS C, 
           TA_REDUNDANT_DATA_LOOKUP D
     WHERE A.DL_JOB_ID = B.DL_ID 
           AND
           B.DL_REPORT_ID = ? 
           AND
           B.DL_CLIENT_ID = C.DL_ID 
           AND
           A.DL_ITEM_PATH_ID = D.DL_ID
     GROUP BY A.DL_JOB_ID,
              A.DL_ITEM_PATH_ID
     ORDER BY A.DL_JOB_ID,
               A.DL_ITEM_PATH_ID 
);
 
DELIMITER1

	$sth = $slowDBH->prepare($sql1);

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

sub writeValueToDropbox1 {
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
		  "UPDATE TA_DROPBOX SET DS_VALUE=\"$value1\" WHERE DS_KEY=\"$key1\"";

		my $sth = $fastDBHTmp->prepare($sql1);

		my $rows_affected = $sth->execute();

		$sth->finish();   # end statement, release resources (not a transaction)

		if ( $rows_affected == 1 ) {

			$subresult = 1;

		}
		else {

			logEvent( 2,
"Error 1 occured in writeValueToDropbox1(): Key '$key1' does not exist."
			);

		}

		$fastDBHTmp->disconnect();

		return
		  ; # returns only from this eval block, not from the sub. Very "smart" feature of Perl...

	};

	if ($@) {

		logEvent( 2, "Error 2 occured in writeValueToDropbox1(): $@" );

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

sub getDatabaseCachingStatus() {
	my $result1;
	my $shellExecResult;

## run Fincore

	( $shellExecResult, @collectedDetails_cmdFincore ) =
	  executeShellCommand("$basedir/linux-fincore $slowDatabaseFileName");

#	if ( $shellExecResult == 1 ) {
#
#		$executionResult_cmdFincore = 0;
#		parsedetails_cmdFincore(@collectedDetails_cmdFincore);
#
#	}
#	else {
#		$executionResult_cmdFincore = 1;
#		$failedShellCommandsCount++;
#	}

$executionResult_cmdFincore = 0;
parsedetails_cmdFincore(@collectedDetails_cmdFincore);


## run Free

	( $shellExecResult, @collectedDetails_cmdFree ) =
	  executeShellCommand("free -b");

#	if ( $shellExecResult == 1 ) {
#
#		$executionResult_cmdFree = 0;
#		parsedetails_cmdFree(@collectedDetails_cmdFree);
#
#	}
#	else {
#		$executionResult_cmdFree = 1;
#		$failedShellCommandsCount++;
#	}


		$executionResult_cmdFree = 0;
		parsedetails_cmdFree(@collectedDetails_cmdFree);

		$failedShellCommandsCount=0;
	

	if ( $failedShellCommandsCount == 0 ) {

		my $memoryRequiredforCaching = 0;

		if ( $databaseSize > $databaseCachedSize ) {

			$memoryRequiredforCaching = $databaseSize - $databaseCachedSize;
		}

		if ( $memoryAvailableForCache > $memoryRequiredforCaching ) {
			$result1 = "OK -";
		}
		else {
			$result1 = "PROBLEM -";
		}

		$result1 .=
		    " database cached $databaseCachedPercentage% of total "
		  . bytesToHuman($databaseSize)
		  . " , cache required "
		  . bytesToHuman($memoryRequiredforCaching)
		  . " , memory available "
		  . bytesToHuman($memoryAvailableForCache);
	}
	else {

		$result1 = "ERROR - unable to run shell, check log file for more info";

	}

	return $result1;

}

#sub getDatabaseCachingStatus() {
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
### run Fincore
#
#	if (
#		runShell(
#			"$basedir/linux-fincore $slowDatabaseFileName",
#			\@collectedDetails_cmdFincore
#		)
#	  )
#	{
#
#		$executionResult_cmdFincore = 0;
#		parsedetails_cmdFincore(@collectedDetails_cmdFincore);
#
#	}
#	else {
#		$executionResult_cmdFincore = 1;
#		$failedShellCommandsCount++;
#	}
#
### run Free
#
#	if ( runShell( "free -b", \@collectedDetails_cmdFree ) ) {
#
#		$executionResult_cmdFree = 0;
#		parsedetails_cmdFree(@collectedDetails_cmdFree);
#
#	}
#	else {
#		$executionResult_cmdFree = 1;
#		$failedShellCommandsCount++;
#	}
#
#	if ( $failedShellCommandsCount == 0 ) {
#
#		my $memoryRequiredforCaching = 0;
#
#		if ( $databaseSize > $databaseCachedSize ) {
#
#			$memoryRequiredforCaching = $databaseSize - $databaseCachedSize;
#		}
#
#		if ( $memoryAvailableForCache > $memoryRequiredforCaching ) {
#			$result1 = "OK -";
#		}
#		else {
#			$result1 = "PROBLEM -";
#		}
#
#		$result1 .=
#		    " database cached $databaseCachedPercentage% of total "
#		  . bytesToHuman($databaseSize)
#		  . " , cache required "
#		  . bytesToHuman($memoryRequiredforCaching)
#		  . " , memory available "
#		  . bytesToHuman($memoryAvailableForCache);
#	}
#	else {
#
#		$result1 = "ERROR - unable to run shell, check log file for more info";
#
#	}
#
#	return $result1;
#
#}

sub parsedetails_cmdFincore {
	my (@data) = @_;
	my $dataLine = @data[2];

	$dataLine =~ /(\S*)\s*(\S*)\s*(\S*)\s*(\S*)\s*(\S*)\s*(\S*)\s*(\S*)$/;

	$databaseSize             = $2;
	$databaseCachedSize       = $6;
	$databaseCachedPercentage = $7;

	$databaseSize       =~ s/,//g;
	$databaseCachedSize =~ s/,//g;

	#	logEvent( 1, "databaseSize : $databaseSize" );
	#	logEvent( 1, "databaseCachedSize : $databaseCachedSize" );
	#	logEvent( 1, "databaseCachedPercentage : $databaseCachedPercentage" );

}

sub parsedetails_cmdFree {
	my (@data) = @_;
	my $dataLine = @data[1];

	$dataLine =~ /^Mem:\s*(\S*)\s*(\S*)\s*(\S*)/;

	$memoryAvailableForCache = $3;

	#logEvent( 1, "memoryAvailableForCache : $memoryAvailableForCache" );

}

#
#sub runShell {
#	my ( $cmd, $collectedDetails_ref ) =
#	  @_;    # expects reference to $collectedDetails
#
#	logEvent( 1, "Executing Shell command : $cmd" );
#
#	my ( $sshReadBuffer, $errput ) =
#	  $ssh_pipe->capture2( { timeout => 30, stdin_discard => 1 }, $cmd )
#	  ; # doco says that capture function honours input separator settings (local $/ = "\n";) when in array context, but really it does not...
#
##	!Don't use statement " || { logEvent( 2, "Error 1 occured in query_hypervisor() : " . $ssh_pipe->error )
##		  && return 0 }; " in here or $errput will not be retrieved correctly...
#
#	if ( $ssh_pipe->error ) {
#		if ( !( $ssh_pipe->error =~ /^child exited with code.*/ ) )
#		{ # we make exception for Fincore, it returns this code when completed successfuly
#
#			logEvent( 2,
#				"Error 1 occured in runShell(), Net::SSH error : "
#				  . $ssh_pipe->error );
#			return 0;
#
#		}
#	}
#
#	if ( !( $errput eq "" ) )
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
	logEvent( 1, "Execution output:" . Dumper(@execOutput) );

	#logEvent( 1, "STDERR output: $stdErr" );

	if ( ( $execResultCode eq "0" ) || ( $execResultCode eq "26" ) || ( $execResultCode eq "27" ))
	{
		$resultValue = 1;
	}
	else {

		logEvent( 2,
"Error 4 in executeShellCommand(): Execution result code is $execResultCode ($cmd1)"
		);

	}

	return ( $resultValue, @execOutput );

}
