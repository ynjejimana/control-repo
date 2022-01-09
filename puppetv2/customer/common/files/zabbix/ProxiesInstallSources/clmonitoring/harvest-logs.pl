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
use Time::Piece;
use Text::CSV;
use File::Find;
use File::Path;
use File::Basename;
use File::Copy;
use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);
use DBI;
use Encode;
no if $] >= 5.018, 'warnings', "experimental::smartmatch";

our $datadir              = "/clmdata";
our $slowDatabaseFileName = "$datadir/database/clmonitoringdata_slow.db";
our $fastDatabaseFileName = "$datadir/database/clmonitoringdata_fast.db";
our $logFileName          = "$datadir/scriptslog/log.txt";
our $logfilesretention    = "$datadir/reportsretention";

my $loggingLevel = 1
  ; # 0 - no logging, 1 - log errors only, 2 - log everything (errors, warnings, debug info)
my $logOutput = 2
  ; # 1 - output to console, 2 - output to log file, 3 - output to both console and log file

my $thisModuleID =
  "HARVEST-LOGS";    # just for log file record identification purposes

my @detailCSV1ImportFormat = (
	"Client",
	"Agent",
	"Instance",
	"Backup Set",
	"Subclient",
	"Storage Policy",
	"Job Id (CommCell)",
	"Status",
	"Type",
	"Scan Type",
	"Start Time",
	"(Write Start Time)",
	"End Time or Current Phase",
	"(Write End Time)",
	"Size of Application",
	"Compression Rate",
	"Data Transferred",
	"Data Written",
	"(Space Saving Percentage)",
	"Data Size Change",
	"Transfer Time",
	"Current Transfer Time",
	"Throughput (GB/Hour)",
	"Current Throughput",
	"Protected Objects",
	"Failed Objects",
	"Failed Folders",
	"MediaAgent",
	"Subclient Content",
	"Scan Type Change Reason",
	"Failure Reason",
	"Job Description"
);

my $reportEncodingUnicode = 1;

my $current_report_id;
my $current_job_id;
my $invalidCommandLine = 0;
my $dataImportDirectory;

#my $importProcedureLock;
my $parseLogDetailFile1ProcessCurrentClientJob;
my $parseLogDetailFile1CompletedJobsFound;
my $csvParser;
my $slowDBH;

#my $fastDBH;

## program entry point
## program initialization

logEvent( 1, "Started" );

my $commandline = join " ", $0, @ARGV;
logEvent( 1, "Used command line: $commandline" );

if ($invalidCommandLine) {

	print <<USAGELABEL;
Invalid command line parameters
	
USAGE:	perl harvest-logs.pl <>


NOTE 1:		Command line parameters are case insensitive	
	
USAGELABEL

	exit 0;
}

## main execution block

#
#my $slowDBH="# ERROR CODE [19:968]: Backup job has been suspended by user lmcdonald. (Error Lookup Site: https://esupport.commvault.com/JPR.aspx?guid=SLMJP`EDELFFD`&msg=Backup job has been suspended by user lmcdonald.&OEMId=1&cliver=0&server=14&ida=33&opType=4&phaseNum=4&messageId=318768072&subSysNum=19&messageNum=968)   # ERROR CODE [19:1327]: Attempt start error: [Inability to connect to remote machine [10.0.36.22].  Please check Network Connectivity or the machine may be down.] (Error Lookup Site: https://esupport.commvault.com/JPR.aspx?guid=SLMJP`EDELFFD`&msg=Attempt start error: [Inability to connect to remote machine [10.0.36.22].  Please check Network Connectivity or the machine may be down.]&OEMId=1&cliver=0&server=14&ida=0&opType=4&phaseNum=0&messageId=318768431&subSysNum=19&messageNum=1327)";
#if ( $slowDBH =~ m/#\sERROR CODE\s\[(\d*:\d*)\]:\s/ ) {
#		$slowDBH = $1;
#	}
#
#

# connect to database

if ( !-f $slowDatabaseFileName ) {
	logEvent( 2, "Database file $slowDatabaseFileName does not exist" );
	exit 1;
}

my $slowDBH = DBI->connect(
	"dbi:SQLite:dbname=$slowDatabaseFileName",
	"", "", { RaiseError => 1 },
  )

  || {
	logEvent( 2,
		"Can't connect to database ($slowDatabaseFileName): $DBI::errstr" )
	  && exit 1
  };

#
#readSettingFromDatabase1( "IMPORT_PROCEDURE_LOCK", \$importProcedureLock )
#  or exit 1;
#
#if ( !defined($importProcedureLock) ) {
#	logEvent( 2, "IMPORT_PROCEDURE_LOCK does not exist in TA_SETTINGS" );
#	exit 1;
#
#}
#
#if ( uc($importProcedureLock) ne "NIL" ) {
#
#	logEvent( 1,
#"Can't proceed with import at this time, previous import procedure has not completed yet. IMPORT_PROCEDURE_LOCK="
#		  . $importProcedureLock );
#	exit 1;
#}
#
#my $timeStamp = localtime->strftime("%Y-%m-%d %H:%M:%S.");
#writeSettingToDatabase1( "IMPORT_PROCEDURE_LOCK", $timeStamp ) or exit 1;

# maintain TA_COLLECTED_DATA table (delete outdated records)
#

maintainReportDatabaseRetention() or exit 1;

#exit 0;

maintainReportFileRetention() or exit 1;

readSettingFromDatabase1( "DATA_IMPORT_DIRECTORY", \$dataImportDirectory )
  or exit 1;

if ( !defined($dataImportDirectory) ) {
	logEvent( 2, "DATA_IMPORT_DIRECTORY does not exist in TA_SETTINGS" );
	exit 1;

}

## main execution block

find( \&traverseDirectory, $dataImportDirectory );

## end - main execution block

#writeSettingToDatabase1( "IMPORT_PROCEDURE_LOCK", "nil" ) or exit 1;

# disconnect from database
$slowDBH->disconnect()
  || {
	logEvent( 2,
		"Can't disconnect from database ($slowDatabaseFileName): $DBI::errstr" )
	  && exit 1
  };

logEvent( 1, "Finished" );

## end - main execution block

##  program exit point	###########################################################################

############

sub traverseDirectory {
	my $returnValue1 = 0;    #false by default

	my $fullSummaryFileName = File::Spec->rel2abs($_);
	my ( $summaryFileName, $filePath, $suffix ) =
	  fileparse($fullSummaryFileName);
	my $fullDetailFileName;
	my $summaryFileBackupJobsComplete;
	my $summaryFileNamePrefix;

	if (-f) {

		if ( $summaryFileName =~ m/^(.*)_Summary.csv/ ) {
			$summaryFileNamePrefix = $1;
			$fullDetailFileName =
			  $filePath . $summaryFileNamePrefix . "_Details.csv";

			#for (my $loop=0;$loop<10000;$loop++){
			#
			#		parseLogDetailFile1($fullDetailFileName);
			#
			#					logEvent( 1, $loop );
			#}

			if (
				parseLogSummaryFile2(
					$fullSummaryFileName, \$summaryFileBackupJobsComplete
				)
			  )
			{

				if ( $summaryFileBackupJobsComplete > 0 )
				{    # summary file indicated there are backup jobs finished

					if ( parseLogDetailFile1($fullDetailFileName) )
					{    # report successfully imported

						#						unlink($fullSummaryFileName);
						#
						#						logEvent( 1, "Deleted $fullSummaryFileName" );
						#
						#						unlink($fullDetailFileName);
						#						logEvent( 1, "Deleted $fullDetailFileName" );
						moveReportToRetention( $filePath,
							$summaryFileNamePrefix, $current_report_id );

						$returnValue1 = 1;
					}
					else {
						return $returnValue1;
					}

				}
			}
			else {
				return $returnValue1;
			}

		}
	}

	return $returnValue1;
}

sub processLineType1 {
	my ( $line, $fileName ) = @_;
	my $sth;
	my @items;
	my $clientLookupIndex;
	my $subclientLookupIndex;
	my $storagePolicyLookupIndex;
	my $failureErrorCode = "0";

	#logEvent( 1, "line type 1: $line" );

	eval {

# can not use simple split() here because it can not split columns that contain commas surrounded by quotes...
		if ( $csvParser->parse($line) ) {    # parse file into fields

			@items = $csvParser->fields();    # get the parsed fields

		}
		else {

			logEvent( 2, "Unable to parse line '$line' in $fileName" );
		}

		$parseLogDetailFile1ProcessCurrentClientJob = 0;

#		$sth = $slowDBH->prepare("SELECT DL_STATUS FROM TA_CLIENTS WHERE DS_NAME=?");
#		$sth->execute( @items[0] );
#		my $tmp1 = $sth->fetch();
#		$parseLogDetailFile1ProcessCurrentClientJob = @$tmp1[0];
#		$sth->finish();   # end statement, release resources (not a transaction)
#
#
#
#if ($parseLogDetailFile1ProcessCurrentClientJob) {

		#logEvent( 1, "uc(@items[7])" );

		if ( ( uc( @items[7] ) ne "ACTIVE" ) && ( uc( @items[7] ) ne "N/A" ) ) {

			$parseLogDetailFile1ProcessCurrentClientJob = 1;
			$parseLogDetailFile1CompletedJobsFound++;

			logEvent( 1,
"Importing ready-for-review client job '@items[0]', subclient content '@items[28]'"
			);

			storeValueInLookupTable( "TA_CLIENTS", "DS_NAME", @items[0],
				\$clientLookupIndex );

			storeValueInLookupTable( "TA_SUBCLIENTS", "DS_NAME", @items[4],
				\$subclientLookupIndex );

			storeValueInLookupTable( "TA_STORAGE_POLICIES", "DS_NAME",
				@items[5], \$storagePolicyLookupIndex );

			if ( @items[30] =~ m/#\sERROR CODE\s\[(\d*:\d*)\]:\s/ ) {
				$failureErrorCode = $1;
			}

			#print Dumper(@items);

			my $sql1 = <<DELIMITER1;

INSERT INTO TA_JOBS (
	DL_REPORT_ID,
 	DL_CLIENT_ID,
    DS_AGENT,
    DS_INSTANCE,
    DS_BACKUP_SET,
    DL_SUBCLIENT_ID,
    DL_STORAGE_POLICY_ID,
    DS_JOBID,
    DS_STATUS,
    DS_TYPE,
    DS_SCAN_TYPE,
    DS_START_TIME,
    DS_WRITE_START_TIME,
    DS_END_TIME_OR_CURRENT_PHASE,
    DS_WRITE_END_TIME,
    DS_SIZE_OF_APPLICATION,
    DS_COMPRESSION_RATE,
    DS_DATA_TRANSFERRED,
    DS_DATA_WRITTEN,
    DS_SPACE_SAVING_PERCENTAGE,
    DS_DATA_SIZE_CHANGE,
    DS_TRANSFER_TIME,
    DS_CURRENT_TRANSFER_TIME,
    DS_THROUGHPUT,
    DS_CURRENT_THROUGHPUT,
    DS_PROTECTED_OBJECTS,
    DS_FAILED_FOLDERS,
    DS_FAILED_OBJECTS,
    DS_MEDIA_AGENT,
    DS_SUBCLIENT_CONTENT,
    DS_SCAN_TYPE_CHANGE_REASON,
    DS_FAILURE_REASON,
    DS_JOB_DESCRIPTION,
    DS_FAILURE_ERROR_CODE
    )
    VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?); 

DELIMITER1

			# use parametrized query - its safer, cleaner and more convenient
			$sth = $slowDBH->prepare($sql1);
			my $rows_affected = $sth->execute(
				$current_report_id,        $clientLookupIndex,
				@items[1],                 @items[2],
				@items[3],                 $subclientLookupIndex,
				$storagePolicyLookupIndex, @items[6],
				@items[7],                 @items[8],
				@items[9],                 @items[10],
				@items[11],                @items[12],
				@items[13],                @items[14],
				@items[15],                @items[16],
				@items[17],                @items[18],
				@items[19],                @items[20],
				@items[21],                @items[22],
				@items[23],                @items[24],
				@items[25],                @items[26],
				@items[27],                @items[28],
				@items[29],                @items[30],
				@items[31],                $failureErrorCode
			);
			$sth->finish()
			  ;    # end statement, release resources (not a transaction)

			$sth = $slowDBH->prepare("SELECT MAX(DL_ID) FROM TA_JOBS");
			$sth->execute();
			my $tmp1 = $sth->fetch();
			$current_job_id = @$tmp1[0];
			$sth->finish()
			  ;    # end statement, release resources (not a transaction)
		}

		else {

#			logEvent( 1,
#"Skipping not-ready-for-review client job '@items[0]', subclient content '@items[28]'"
#			);

		}

	};
	if ($@) {

		logEvent( 2, "Error 1 occured in processLineType1(): $@" );

	}

}

# a universal method that stores values in a conform lookup table (if they don't already exist there) and returns their index
# stored values must be unique - table constraint must be set, DL_ID primary index must exist
sub storeValueInLookupTable {
	my ( $tableName, $columnName, $data1, $index1 )
	  =    # expects reference to variable $index1 (so it can modify it)
	  @_;
	my $sth;

	$slowDBH->{PrintError} = 0;
	eval
	{ # this ensures flow in cases that the same data were already stored in $tableName

		$sth =
		  $slowDBH->prepare("INSERT INTO $tableName ($columnName) VALUES (?)");

		$sth->execute($data1);
	};
	$slowDBH->{PrintError} = 1;

	#logEvent( 1, "next" );

	$sth->finish();    # end statement, release resources (not a transaction)

	$sth =
	  $slowDBH->prepare("SELECT DL_ID FROM $tableName WHERE $columnName=?");
	$sth->execute($data1);
	my $tmp1 = $sth->fetch();
	$$index1 =
	  @$tmp1[0]
	  ; # dereference array referenced by $tmp1, retrieve its first item and store it in a scalar variable that is referenced by $value1

	$sth->finish();    # end statement, release resources (not a transaction)

}

sub processLineType2 {
	my ( $line, $fileName ) = @_;
	my $failedToBackupResult;
	my $failedToBackupItem;
	my $failedToBackupItemPath;
	my $failedToBackupItemPath_LookupIndex;
	my $failedToBackupItemName;
	my $failedToBackupItemName_LookupIndex;
	my $failedToBackupItemReason;
	my $failedToBackupItemReason_LookupIndex;
	my $sth;

	# 0 - not failed
	# 1 - failed (undefined)
	# 2 - failed Windows
	# 3 - failed Linux/other
	# 4 - failed - unable to get file list
	my $itemType = 1;

	#logEvent( 1, "line type 2: $line" );

	$failedToBackupResult     = "Failed";
	$failedToBackupItemName   = "Undefined - error 1";
	$failedToBackupItemPath   = "Path was not defined";
	$failedToBackupItemReason = "Undefined - error 1";

	if ( $line eq "(Files failed to back up) None" ) {    # not failed

		$failedToBackupResult = "None";
		$itemType             = 0;

	}
	else {                                                # failed

		$itemType = 1;

		if ( $line eq "(Files failed to back up) Unable to get file list" )
		{    # failed - unable to get file list
			$itemType = 4;

			$failedToBackupResult     = "Failed";
			$failedToBackupItemName   = "Unable to get file list";
			$failedToBackupItemPath   = "Path was not defined";
			$failedToBackupItemReason = "Unable to get file list";

		}

	}

	if ( ( $itemType > 0 ) && ( $itemType != 4 ) )   # Windows/Linux item failed
	{

		my $lineTest = $line;
		if ( $lineTest =~ m/^\(Files failed to back up\)\s\[(.*)\]/ )
		{    # item is Windows (is enclosed in [])

			$itemType = 2;

		}
		else {    # item is Linux/other

			$itemType = 3;
		}

		if ( $itemType == 2 )
		{ # item is Windows - sanitize and parse differently Windows-filesystem items (have backslash as path divider and may not contain path at all - just filename)

			$line =~ /^\(Files failed to back up\)\s(\[.*\])\s*(.*)/;

			$failedToBackupResult     = "Failed";
			$failedToBackupItem       = $1;
			$failedToBackupItemReason = $2;

			if ( $failedToBackupItem =~ m/\\/ ) {   # windows item contains path

				$failedToBackupItem =~ /^\[(.*)\\(.*)\]$/;
				$failedToBackupItemName = $2;
				$failedToBackupItemPath = $1;

			}
			else
			{ # windows item does not contain path; some items do not have path, just "filename" or something like that

				$failedToBackupItem =~ /^\[(.*)\]$/;
				$failedToBackupItemName = $1;
				$failedToBackupItemPath = "Path was not defined";

			}

		}

		if ( $itemType == 3 ) {    # item isn't Windows

			$line =~ /^\(Files failed to back up\)\s(\S*)\s*(.*)/;

			$failedToBackupResult     = "Failed";
			$failedToBackupItem       = $1;
			$failedToBackupItemReason = $2;

			#logEvent( 1, "failedToBackupItem X $failedToBackupItem X" );

			#detect, sanitize and parse differently Windows-filesystem items

			$failedToBackupItem =~ /(.*)\/(.*)$/;
			$failedToBackupItemName = $2;
			$failedToBackupItemPath = $1;

		}

	}

	if ( ( $itemType > 0 ) && ( $itemType != 4 ) )
	{ # common block for all failed items. we ignore 4 "unable to get file list" to not write clutter in database (always has a client failure code anyway)

		storeValueInLookupTable( "TA_REDUNDANT_DATA_LOOKUP", "DS_DATA",
			$failedToBackupItemPath, \$failedToBackupItemPath_LookupIndex );

		storeValueInLookupTable( "TA_REDUNDANT_DATA_LOOKUP", "DS_DATA",
			$failedToBackupItemName, \$failedToBackupItemName_LookupIndex );

		storeValueInLookupTable( "TA_REDUNDANT_DATA_LOOKUP", "DS_DATA",
			$failedToBackupItemReason, \$failedToBackupItemReason_LookupIndex );

		# use parametrized query - its safer, cleaner and more convenient
		$sth =
		  $slowDBH->prepare(
"INSERT INTO TA_JOB_ITEMS (DL_JOB_ID,DL_ITEM_PATH_ID,DL_ITEM_NAME_ID,DL_ITEM_REASON_ID) VALUES (?,?,?,?)"
		  );
		my $rows_affected = $sth->execute(
			$current_job_id,
			$failedToBackupItemPath_LookupIndex,
			$failedToBackupItemName_LookupIndex,
			$failedToBackupItemReason_LookupIndex
		);
		$sth->finish();   # end statement, release resources (not a transaction)

	}

	#logEvent( 1, "failedToBackupResult: $failedToBackupResult" );
	#logEvent( 1, "failedToBackupItemName: $failedToBackupItemName" );
	#logEvent( 1, "failedToBackupItemReason: $failedToBackupItemReason" );

}

sub parseLogSummaryFile2 {
	my ( $fileName, $backupJobsComplete ) = @_;

# Expects reference to variable $backupJobsComplete (so it can modify it). Will return the number of client jobs that are completed

	my $currentLineType = 0
	  ; # 0 - client info line, 1 - 'All' clients summary line (usually the second one),  2 - empty line, 3 - column header line (first line in file - to skip)
	my $previousLineType        = 0;    # same meaning as for $currentLineType
	my $lineIndex               = 0;
	my $returnValue1            = 0;    # false by default
	my $foundClientsSummaryLine = 0;

	$$backupJobsComplete = 0;

	logEvent( 1, "Parsing $fileName" );

	if ( $reportEncodingUnicode == 1 ) {

		open( INPUT, "<:encoding(utf8)", $fileName )
		  || ( logEvent( 2, "Can not open file $fileName : $!" )
			&& return $returnValue1 );

	}
	else {
		open( INPUT, $fileName )
		  || ( logEvent( 2, "Can not open file $fileName : $!" )
			&& return $returnValue1 );
	}

	eval {

		# parse report file in the loop
		# parse report file in the loop

		while ( my $line = <INPUT> ) {

			if ( $reportEncodingUnicode == 1 ) {

				$line =~ s/^\x{FEFF}//; # strip BOM
				$line = decode_utf8($line);
				logEvent( 1,
					"parseLogSummaryFile2(): decoded from Unicode: $line" );
			}

			#logEvent( 1, "Line: $line" );

			my @items = split( /,/, $line );

			$currentLineType = 0;

			if ( @items[0] eq "All" ) {
				$currentLineType         = 1;
				$foundClientsSummaryLine = 1;

				$$backupJobsComplete =
				  @items[2] +
				  @items[3] +
				  @items[4] +
				  @items[5] +
				  @items[6] +
				  @items[8];

			}

			if ( $line eq "" ) {
				$currentLineType = 2;
			}

			if ( $lineIndex == 0 ) {

				$currentLineType = 3;
			}

			given ($currentLineType) {
				when (0) {

					#
					#					if ( uc( @items[15] ) eq "CURRENT" ) {
					#
					#
					#
					#					}
					#					else {
					#
					#
					#
					#					}

				}

				when (2) {    # skip empty line

				}
				when (3) {    # skip header line

				}
			}

			$previousLineType = $currentLineType;
			$lineIndex++;
		}

		close(INPUT);

		$returnValue1 = 1;

	};
	if ($@) {

		logEvent( 2, "Error 3 occured in parseLogSummaryFile2(): $@" );

	}

	if ( !$foundClientsSummaryLine ) {
		logEvent( 2,
"Error 4 occured in parseLogSummaryFile2(): could not find 'clients summary' line."
		);
		$returnValue1 = 0;
	}

	logEvent( 1, "Found $$backupJobsComplete complete client jobs" );

	return $returnValue1;

}


sub parseLogDetailFile1 {
	my ($fileName) = @_;
	my $currentLineType = 0
	  ; # 0 - undefined, 1 - standard item header line, 2 - standard item detail line, 3 - empty line, 4 - header line (first line in file)
	my $previousLineType = 0;    # same meaning as for $currentLineType
	my $lineIndex        = 0;
	my $sth;
	my $returnValue1 = 0;        # false by default

	logEvent( 1, "Importing $fileName" );

	if ( $reportEncodingUnicode == 1 ) {

		open( INPUT, "<:encoding(utf8)", $fileName )
		  || (
			(
				logEvent( 2, "Can not open file $fileName : $!" )
				&& return $returnValue1
			)
		  );

	}
	else {

		open( INPUT, $fileName )
		  || (
			(
				logEvent( 2, "Can not open file $fileName : $!" )
				&& return $returnValue1
			)
		  );

	}

	eval {

		$parseLogDetailFile1CompletedJobsFound = 0;

		$csvParser = Text::CSV->new();

		$slowDBH->begin_work();

		# write report info to database

		# use parametrized query - its safer, cleaner and more convenient
		$sth =
		  $slowDBH->prepare("INSERT INTO TA_REPORTS (DS_FILENAME) VALUES (?)");
		my $rows_affected = $sth->execute($fileName);
		$sth->finish();   # end statement, release resources (not a transaction)

		$slowDBH->commit()
		  ; # commit to database so the import status reading functionality can read this freshest info
		$slowDBH->begin_work();

		$sth = $slowDBH->prepare("SELECT MAX(DL_ID) FROM TA_REPORTS");
		$sth->execute();
		my $tmp1 = $sth->fetch();
		$current_report_id = @$tmp1[0];    # get id of the just created report
		$sth->finish();   # end statement, release resources (not a transaction)

		# parse report file in the loop

		while ( my $line = <INPUT> ) {

			if ( $reportEncodingUnicode == 1 ) {
				$line =~ s/^\x{FEFF}//; # strip BOM				
				$line = decode_utf8($line);
				logEvent( 1,
					"parseLogDetailFile1(): decoded from Unicode: $line" );
			}

			$line =~ s/\R//g;    # clean line breaks

			#logEvent( 1, "Line: $line" );

			$currentLineType = 1;

			if ( $line =~ /^\(Files failed to back up\)/ ) {
				$currentLineType = 2;
			}

			if ( !defined($line) || ( $line eq "" ) ) {
				$currentLineType = 3;
			}

			if ( $lineIndex == 0 ) {

				$currentLineType = 4;
			}

			given ($currentLineType) {
				when (1) {
					processLineType1( $line, $fileName );
				}

				when (2) {
					if ($parseLogDetailFile1ProcessCurrentClientJob) {
						processLineType2( $line, $fileName );
					}
				}
				when (3) {    # skip empty line

				}
				when (4) {    # verify header line, terminate if incompatible

					if ( !verifyCSV1DetailColumnCompatibility($line) ) {

						eval { $slowDBH->rollback(); };

						$sth =
						  $slowDBH->prepare(
							"DELETE FROM TA_REPORTS WHERE DL_ID=?");
						my $rows_affected = $sth->execute($current_report_id);
						$sth->finish()
						  ; # end statement, release resources (not a transaction)

						#$slowDBH->commit();

						return $returnValue1;

					}

				}

			}

			$previousLineType = $currentLineType;
			$lineIndex++;
		}

		# use parametrized query - its safer, cleaner and more convenient
		$sth =
		  $slowDBH->prepare(
"UPDATE TA_REPORTS SET DT_IMPORT_FINISHED=datetime('now','localtime') WHERE DL_ID=?"
		  );
		my $rows_affected = $sth->execute($current_report_id);
		$sth->finish();   # end statement, release resources (not a transaction)

		$slowDBH->commit();

		close(INPUT);

		$returnValue1 = 1;

	};
	if ($@) {

		logEvent( 2, "Error 1 occured in parseLogDetailFile1(): $@" );

		eval { $slowDBH->rollback(); };

	}

	logEvent( 1,
"Imported $parseLogDetailFile1CompletedJobsFound ready-for-review client jobs"
	);

	return $returnValue1;

}

sub moveReportToRetention {
	my ( $filePath, $fileNameBase, $reportId ) = @_;

	logEvent( 1, "Moving report files to retention" );

	eval {

		mkdir("$logfilesretention/$reportId-$fileNameBase");

		move(
			$filePath . $fileNameBase . "_Summary.csv",
			"$logfilesretention/$reportId-$fileNameBase/$fileNameBase"
			  . "_Summary.csv"
		);
		move(
			$filePath . $fileNameBase . "_Details.csv",
			"$logfilesretention/$reportId-$fileNameBase/$fileNameBase"
			  . "_Details.csv"
		);

	};
	if ($@) {

		logEvent( 2, "Error 1 occured in moveReportToRetention(): $@" );

	}

}

sub deleteReportFromDatabase {
	my ($reportId) = @_;
	my $subresult = 0;

	eval {

		logEvent( 1, "Deleting report $reportId" );

		## delete report

		my $sth =
		  $slowDBH->prepare(
"DELETE FROM TA_JOB_ITEMS WHERE DL_JOB_ID IN (SELECT DL_ID FROM TA_JOBS WHERE DL_REPORT_ID=?)"
		  );

		$sth->execute($reportId);

		$sth->finish();

		my $sth = $slowDBH->prepare("DELETE FROM TA_JOBS WHERE DL_REPORT_ID=?");

		$sth->execute($reportId);

		$sth->finish();

		my $sth = $slowDBH->prepare("DELETE FROM TA_REPORTS WHERE DL_ID=?");

		$sth->execute($reportId);

		$sth->finish();

		## delete unreferenced lookup rows

		logEvent( 1, "Deleting unreferenced lookup rows" );

		my $sth =
		  $slowDBH->prepare(
"DELETE FROM TA_CLIENTS WHERE DL_ID NOT IN (SELECT DISTINCT DL_CLIENT_ID FROM TA_JOBS)"
		  );

		$sth->execute();

		$sth->finish();

		my $sth =
		  $slowDBH->prepare(
"DELETE FROM TA_REDUNDANT_DATA_LOOKUP WHERE ((DL_ID NOT IN (SELECT DISTINCT DL_ITEM_PATH_ID FROM TA_JOB_ITEMS)) AND (DL_ID NOT IN (SELECT DISTINCT DL_ITEM_NAME_ID FROM TA_JOB_ITEMS)) AND (DL_ID NOT IN (SELECT DISTINCT DL_ITEM_REASON_ID FROM TA_JOB_ITEMS)))"
		  );

		$sth->execute();

		$sth->finish();

		my $sth =
		  $slowDBH->prepare(
"DELETE FROM TA_STORAGE_POLICIES WHERE DL_ID NOT IN (SELECT DISTINCT DL_STORAGE_POLICY_ID FROM TA_JOBS)"
		  );

		$sth->execute();

		$sth->finish();

		my $sth =
		  $slowDBH->prepare(
"DELETE FROM TA_SUBCLIENTS WHERE DL_ID NOT IN (SELECT DISTINCT DL_SUBCLIENT_ID FROM TA_JOBS)"
		  );

		$sth->execute();

		$sth->finish();

		$subresult = 1;

	};

	if ($@) {

		logEvent( 2, "Error 1 occured in deleteReportFromDatabase(): $@" );

	}

	return $subresult;

}

sub getDatabaseInternalSpaceUsageSize {
	my $subresult = 0;

	my $databasePageSize = getDatabasePragmaStat("page_size");

	if ( $databasePageSize == -1 ) {
		$subresult = -1;
	}

	my $databaseUnusedPages = getDatabasePragmaStat("freelist_count")
	  ;    # pragma freelist_count gets number of unused database pages

	if ( $databaseUnusedPages == -1 ) {
		$subresult = -1;
	}

	my $databaseTotalPages = getDatabasePragmaStat("page_count");

	if ( $databaseTotalPages == -1 ) {
		$subresult = -1;
	}

	if ( $subresult == 0 ) {

		$subresult =
		  ( $databaseTotalPages - $databaseUnusedPages ) * $databasePageSize;

		logEvent( 1,
			"Current DatabaseInternalSpaceUsageSize: "
			  . bytesToHuman($subresult) );

		return $subresult;

	}
	else {

		return $subresult;
	}

}

sub getOldestExistingReportId {
	my $subresult = -1;

	eval {
		my $sth =
		  $slowDBH->prepare("SELECT DL_ID FROM TA_REPORTS ORDER BY DL_ID");

		$sth->execute();

		my @rowArray1;

		@rowArray1 = $sth->fetchrow_array();

		if ( defined( @rowArray1[0] ) ) {
			$subresult = @rowArray1[0];
		}
	};

	if ($@) {

		logEvent( 2, "Error 1 occured in getOldestExistingReportId(): $@" );

	}

	return $subresult;

}

sub getDatabasePragmaStat {
	my ($pragmaStatName) = @_;
	my $subresult = -1;

	eval {
		my $sth = $slowDBH->prepare("PRAGMA $pragmaStatName");

		$sth->execute();

		my @rowArray1;

		@rowArray1 = $sth->fetchrow_array();

		$subresult = @rowArray1[0];

	};

	if ($@) {

		logEvent( 2, "Error 1 occured in getDatabasePragmaStat(): $@" );

	}

	return $subresult;

}

sub maintainReportDatabaseRetention {
	my $subresult = 0;

	my $maxDatabaseSize;
	my $deletedReportCount = 0;
	my $databaseInternalSpaceUsageSize;
	my $deleteReportId;

	eval {

		readSettingFromDatabase1( "DATABASE_MAX_DATA_SIZE", \$maxDatabaseSize )
		  or return $subresult;

		logEvent( 1,
			"Maintaining database retention, maxDatabaseInternalSize: "
			  . bytesToHuman($maxDatabaseSize) );

		$deleteReportId = 0;

		$databaseInternalSpaceUsageSize = getDatabaseInternalSpaceUsageSize();

		while (( $maxDatabaseSize < $databaseInternalSpaceUsageSize )
			&& ( $deleteReportId > -1 ) )
		{

			$deleteReportId = getOldestExistingReportId();

			if ( $deleteReportId > -1 ) {

				deleteReportFromDatabase($deleteReportId);

				$deletedReportCount++;

				$databaseInternalSpaceUsageSize =
				  getDatabaseInternalSpaceUsageSize();

			}

		}

		logEvent( 1,
"Deleted $deletedReportCount reports, new database internal space usage size: "
			  . bytesToHuman($databaseInternalSpaceUsageSize) );

		$subresult = 1;

	};

	if ($@) {

		logEvent( 2,
			"Error 1 occured in maintainReportDatabaseRetention(): $@" );

	}

	return $subresult;

}

sub deleteReportFromFileRetention {
	my ($reportId) = @_;

	eval {

		my @fileList =
		  <$logfilesretention/$reportId-*>
		  ;    # get list of files that match wildcard condition

		foreach my $item (@fileList) {

			logEvent( 1, "Deleting from Report Retention: $item" );

			rmtree($item);
		}

	};
	if ($@) {

		logEvent( 2, "Error 1 occured in deleteReportFromFileRetention(): $@" );

	}

}

sub maintainReportFileRetention {
	my $subresult = 0;
	my $reportFilesRetentionPeriod;

	readSettingFromDatabase1( "REPORT_FILES_RETENTION_PERIOD",
		\$reportFilesRetentionPeriod )
	  or return $subresult;

	if ( !defined($reportFilesRetentionPeriod) ) {
		logEvent( 2,
			"REPORT_FILES_RETENTION_PERIOD does not exist in TA_SETTINGS" );
		return $subresult;

	}

	eval {

		my $sql1 =
"SELECT DL_ID FROM TA_REPORTS WHERE DATETIME(DT_IMPORT_FINISHED)<DATETIME(DATETIME( 'now' , 'localtime' ),'-"
		  . $reportFilesRetentionPeriod
		  . " day')";

		my $sth = $slowDBH->prepare($sql1);

		$sth->execute();

		my @rowArray;

		while ( @rowArray = $sth->fetchrow_array() ) {

			deleteReportFromFileRetention( @rowArray[0] );

		}

		$sth->finish();   # end statement, release resources (not a transaction)

		$subresult = 1;
	};

	if ($@) {

		logEvent( 2, "Error 1 occured in maintainReportFileRetention(): $@" );

	}

	return $subresult;

}

sub verifyCSV1DetailColumnCompatibility {
	my ($line) = @_;
	my $result = 1;

	my @items = split( /,/, $line );

	for ( my $loop = 0 ; $loop < 32 ; $loop++ ) {

		if ( @items[$loop] ne @detailCSV1ImportFormat[$loop] ) {

			logEvent( 2,
"Error 1 occured in verifyCSV1DetailColumnCompatibility(): incompatible format in Detail CSV file. Column #$loop should be '@detailCSV1ImportFormat[$loop]'("
				  . length( @detailCSV1ImportFormat[$loop] )
				  . " bytes) and is '@items[$loop]'("
				  . length( @items[$loop] )
				  . " bytes)." );
			$result = 0;
			last;

		}

	}

	return $result;

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

sub bytesToHuman {
	my $size_in_bytes = shift;

	if ( $size_in_bytes > ( 1024 * 1024 ) ) {

		return sprintf( "%.1f", ( $size_in_bytes / ( 1024 * 1024 ) ) ) . "MB";

	}
	else {

		return sprintf( "%.1f", ( $size_in_bytes / 1024 ) ) . "KB";

	}

}
