#!/usr/bin/perl
#### Verifies non-duplicity of the records in snmptt.conf.xxx files (MIB conversions), allows for joining them together
#### Version 2.32
#### Writen by: Premysl Botek (pbotek@harbourmsp.com)
##################################################################################
#### Execution Requirements:
#### * All non-default Perl modules installed from section "use" below (i.e $ yum install perl-Config-Simple perl-Time-HiRes etc.)
##################################################################################

## pragmas, global variable declarations, environment setup

use v5.10;
use strict;
use Config::Simple;
use Data::Dumper;
use File::Find;
use File::Path;
use File::Basename;
use Switch;
use Time::Piece;
use Time::Seconds;
use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);
use FindBin '$Bin';
use Digest::MD5 qw(md5 md5_hex md5_base64);
use Data::GUID;
no if $] >= 5.018, 'warnings', "experimental::smartmatch";

# DEPENDENT SETTINGS (values need to be reverified/set correctly during each installation - for this script to work and be integrated with the rest of functionality)

my $loggingLevel = 2
  ; # 0 - no logging, 1 - log errors only, 2 - log everything (errors, warnings, debug info)
my $logOutput = 3
  ; # 1 - output to console, 2 - output to log file, 3 - output to both console and log file

our $baseDir     = $Bin;
our $logFileName = "$baseDir/log.txt";

## End - DEPENDENT SETTINGS

my $thisModuleID =
  "MIB-CONVERSIONS-MNGR";    # just for log file record identification purposes

my $appMode = 0;

my $returnValue;
my $invalidCommandLine = 1;

my %globOIDHashTable = ();

# master file info
my @mibSections1_StartLines;
my @mibSections1_EndLines;
my @mibSections1_Titles;
my @mibSections1_MD5Checksums;

# reference file info
my @mibSections2_StartLines;
my @mibSections2_EndLines;
my @mibSections2_Titles;
my @mibSections2_MD5Checksums;

my $check1MasterFile;
my $check1SecondaryFile;

my $check2MasterFile;

my $check3MasterFile;
my $check3StartLineNumber;
my $check3EndLineNumber;

my $check4MasterFile;
my $check4StartLineNumber;
my $check4EndLineNumber;

my $action1MasterFile;

my $action2SourceDir;
my $action2DestFile;

my $duplicateCounter  = 0;
my $recordsCounter    = 0;
my $mibSectionCounter = 0;

## program entry point
## program initialization

if ( ( scalar @ARGV ) < 2 ) {
	$invalidCommandLine = 1;
}
else {

	$invalidCommandLine = 1;

	given ( uc( $ARGV[0] ) ) {

		when (1) {    # check duplications; result prints on the console

			$appMode             = 1;
			$check1MasterFile    = $ARGV[1];
			$check1SecondaryFile = $ARGV[2];

			$invalidCommandLine = 0;

		}

		when (2) {    # list mib sections; result prints on the console

			$appMode            = 2;
			$check2MasterFile   = $ARGV[1];
			$invalidCommandLine = 0;

		}

		when (3) { # copy file section (lines) ; result is in file .copied.lines

			$appMode               = 3;
			$check3MasterFile      = $ARGV[1];
			$check3StartLineNumber = $ARGV[2];
			$check3EndLineNumber   = $ARGV[3];

			$invalidCommandLine = 0;

		}

		when (4) {    # remove file section (lines); result is in file .pruned

			$appMode               = 4;
			$check4MasterFile      = $ARGV[1];
			$check4StartLineNumber = $ARGV[2];
			$check4EndLineNumber   = $ARGV[3];

			$invalidCommandLine = 0;

		}

		when (5)
		{ # expand snmptt.conf file. result goes to a new directory of the same name + .expanded

			$appMode            = 5;
			$action1MasterFile  = $ARGV[1];
			$invalidCommandLine = 0;

		}

		when (6) {   # join files from specified directory into snmptt.conf file

			$appMode            = 6;
			$action2SourceDir   = $ARGV[1];
			$action2DestFile    = $ARGV[2];
			$invalidCommandLine = 0;

		}

	}

	if ($invalidCommandLine) {

		my $commandline = join " ", $0, @ARGV;

		print <<USAGELABEL;
Invalid command line parameters

1 <snmptt.conf file> [reference snmptt.conf file] : check for duplications; result prints on the console

2 <snmptt.conf file> : list mib sections; result prints on the console

3 <snmptt.conf file> <start line number> <end line number> : export file section (lines); result is in file .copiedlines

4 <snmptt.conf file> <start line number> <end line number> : remove file section (lines); result is in file .pruned

5 <snmptt.conf file> : expand snmptt.conf file to separate files by the mib sections. result goes to a new directory of the same name + .expanded

6 <source directory> <resulting snmptt.conf file> : join files from specified directory into snmptt.conf file


USAGELABEL

		exit 0;
	}

## main execution block

	given ($appMode) {

		when (1) {
			fnCheck1();
		}

		when (2) {
			fnCheck2();
		}

		when (3) {
			fnCheck3();
		}

		when (4) {
			fnCheck4();
		}

		when (5) {
			fnAction1();
		}

		when (6) {
			fnAction2();
		}

	}

## end - main execution block

##  program exit point	###########################################################################

	sub traverseDirectory1 {

		#	my $returnValue1 = 0;    #false by default

		my $fullSummaryFileName = File::Spec->rel2abs($_);
		my ( $fileName, $filePath, $suffix ) = fileparse($fullSummaryFileName);
		
		
					logEvent( 1, "Found $fullSummaryFileName" );
		
		

		if (-f) {

			logEvent( 1, "Adding $fileName" );

			my $cmd1 = "cat $filePath/$fileName >> $action2DestFile";

			`$cmd1`

		}

		#	return $returnValue1;
	}

	sub fnAction2 {
		my $itemCounter = 0;

		logEvent( 1, "fnAction2(): started" );
		logEvent( 1, "fnAction2(): scanning " . $action2SourceDir );

		unlink $action2DestFile;

		find( \&traverseDirectory1, $action2SourceDir );
		
		logEvent( 1, "fnAction2(): finished" );
		

	}

	sub addItemToGlobHashTable {
		my ( $zabbixHost, $key, $msg ) = @_;

	}

	sub saveMibSectionToFile {
		my ( $outputPath, $mibSectionName, $mibSectionContent, $recordsCount )
		  = @_;

		my $outputFileName = "$outputPath/$mibSectionName";

		if ( $recordsCount == 0 ) {

			logEvent( 1, "WARNING: $mibSectionName is empty, not saving." );

		}
		else {

			logEvent( 1, "Saving section $mibSectionName" );

			if ( -e $outputFileName ) {

				my $uniqueIdString = Data::GUID->new->as_string;
				$uniqueIdString =~ s/-//g;    # remove hyphens

				$outputFileName .= ".$uniqueIdString";

				logEvent( 1,
"WARNING: File name collision detected. Renaming to $mibSectionName.$uniqueIdString"
				);

			}

			if ( !open( OUTPUT, ">>$outputFileName" ) ) {

				logEvent( 2,
"Error 1 occured in saveMibSectionToFile(): can not open output file $outputFileName : $!"
				);
			}
			else {

				print OUTPUT $mibSectionContent;

				close(OUTPUT);

			}

		}

	}

	sub fnAction1 {
		my $cmd1;
		my $lineCounter = 0;
		my $currentMIBName;
		my $recordsCounter    = 0;
		my $mibSectionCounter = 0;
		my $currentMIBSectionContent;

		my ( $file, $dir, $ext ) = fileparse($action1MasterFile);
		$dir .= $file . ".expanded";

		logEvent( 1, "Cleaning $dir" );

		rmtree $dir;

		mkdir($dir);

		if ( !open( INPUT, $action1MasterFile ) )

		{
			logEvent( 2,
"Error 1 occured in fnAction1(): can not open input file $action1MasterFile : $!"
			);
		}

		#print "\n";

		while ( my $line = <INPUT> ) {

			$lineCounter++;

			if ( $line =~ /^EVENT / ) {

				$recordsCounter++;

			}

			if ( $line =~ /^MIB: / ) {

				if ($currentMIBName) {
					$mibSectionCounter++;
					saveMibSectionToFile( $dir, $currentMIBName,
						$currentMIBSectionContent, $recordsCounter );
				}

				$currentMIBSectionContent = "";
				$recordsCounter           = 0;

				my @columns = split( ' ', $line );

				$currentMIBName = "@columns[1]";

			}

			$currentMIBSectionContent .= $line;

		}

		if ($currentMIBName) {
			$mibSectionCounter++;
			saveMibSectionToFile( $dir, $currentMIBName,
				$currentMIBSectionContent, $recordsCounter );
		}

		close(INPUT);

		logEvent( 1, "Finished. Found $mibSectionCounter sections" );

	}

	sub pruneFile1 {
		my ($fileName) = @_;
		my $lineCounter = 0;
		my $currentMIBName;
		my $currentMIBSectionContent;

		if ( !open( INPUT, $fileName ) )

		{
			logEvent( 2,
"Error 1 occured in pruneFile1(): can not open input file $fileName : $!"
			);
		}

		print "\n";

		while ( my $line = <INPUT> ) {

			$lineCounter++;

	   #			if ( $line =~ /^MIB: / ) {
	   #				$currentMIBSectionMD5Checksum=md5_base64($currentMIBSectionContent);
	   #				$currentMIBSectionContent="";
	   #
	   #			}
	   #
	   #			$currentMIBSectionContent .= $line;

			if ( $line =~ /^EVENT / ) {

				$recordsCounter++;

				my @columns = split( ' ', $line );

				if ( defined( $globOIDHashTable{ @columns[2] } ) )
				{ # if record with this oid already exists in hash table, throw error

					logEvent(
						2,
"Item collision detected. OID on line $globOIDHashTable{ @columns[2]} [master file, mib section "
						  . getMibSectionInfo1(
							$globOIDHashTable{ @columns[2] }
						  )
						  . "] ==  OID on line "
						  . $lineCounter
						  . " [reference file, mib section "
						  . getMibSectionInfo2( $lineCounter,
							$globOIDHashTable{ @columns[2] } )
						  . "]\n"
					);

					$duplicateCounter++;

				}
				else {    # # if record with this oid doesnt exist

					$globOIDHashTable{ @columns[2] } = $lineCounter;

				}

			}

		}
		close(INPUT);

	}

	sub pruneFile2 {
		my ( $fileName, $silent, $sourceFileIdent ) = @_;
		my $lineCounter = 0;
		my $currentMIBName;
		my $currentMIBLineStart;
		my $lineCopyMode = 1;
		my $currentMIBSectionContent;

		if ( !open( INPUT, $fileName ) )

		{
			logEvent( 2,
"Error 1 occured in pruneFile2(): can not open input file $fileName : $!"
			);
		}

		while ( my $line = <INPUT> ) {

			$lineCounter++;

			if ( $line =~ /^MIB: / ) {

				if ( $silent == 0 ) {

					logEvent( 1,
"MIB section $mibSectionCounter: $currentMIBName, lines $currentMIBLineStart - "
						  . ( $lineCounter - 1 ) );
				}

				if ( $sourceFileIdent == 1 ) {

					push( @mibSections1_StartLines, $currentMIBLineStart );
					push( @mibSections1_EndLines,   $lineCounter - 1 );
					push( @mibSections1_Titles,     $currentMIBName );
					push( @mibSections1_MD5Checksums,
						md5_base64($currentMIBSectionContent) );
				}
				else {
					push( @mibSections2_StartLines, $currentMIBLineStart );
					push( @mibSections2_EndLines,   $lineCounter - 1 );
					push( @mibSections2_Titles,     $currentMIBName );
					push( @mibSections2_MD5Checksums,
						md5_base64($currentMIBSectionContent) );
				}

				$currentMIBSectionContent = "";

				$mibSectionCounter++;

				$currentMIBLineStart = $lineCounter;

				my @columns = split( ' ', $line );

				$currentMIBName = "@columns[1]@columns[2]";

			}
			else
			{ # dont include "MIB" line in MD5 digest or content will be always different (timestamp etc.)

				$currentMIBSectionContent .= $line;

			}

		}

		if ( $silent == 0 ) {
			logEvent( 1,
"MIB section $mibSectionCounter: $currentMIBName, lines $currentMIBLineStart - "
				  . ($lineCounter) );
		}

		if ( $sourceFileIdent == 1 ) {

			push( @mibSections1_StartLines, $currentMIBLineStart );
			push( @mibSections1_EndLines,   $lineCounter );
			push( @mibSections1_Titles,     $currentMIBName );
		}
		else {
			push( @mibSections2_StartLines, $currentMIBLineStart );
			push( @mibSections2_EndLines,   $lineCounter );
			push( @mibSections2_Titles,     $currentMIBName );

		}

		close(INPUT);

	}

	sub pruneFile3 {
		my ($fileName) = @_;
		my $lineCounter = 0;
		my $currentMIBName;
		my $outputfilename;
		my $lineCopyMode = 1
		  ; #0 - disabled, 1 - copy on, 2 - waiting for next "EVENT" or "MIB" line

		if ( !open( INPUT, $fileName ) )

		{
			logEvent( 2,
"Error 1 occured in pruneFile3(): can not open input file $fileName : $!"
			);
		}

		$outputfilename =
		    "$fileName.copiedlines"
		  . $check3StartLineNumber . "-"
		  . $check3EndLineNumber . ".txt";
		unlink $outputfilename;

		if ( !open( OUTPUT, ">>$outputfilename" ) ) {

			logEvent( 2,
"Error 2 occured in pruneFile3(): can not open output file $fileName : $!"
			);
		}

		while ( my $line = <INPUT> ) {

			$lineCounter++;

			if (   ( $lineCounter >= $check3StartLineNumber )
				&& ( $lineCounter <= $check3EndLineNumber ) )
			{

				print OUTPUT "$line";

			}

		}

		close(OUTPUT);

		close(INPUT);

	}

	sub pruneFile4 {
		my ($fileName) = @_;
		my $lineCounter = 0;
		my $currentMIBName;
		my $outputfilename;

		if ( !open( INPUT, $fileName ) )

		{
			logEvent( 2,
"Error 1 occured in pruneFile4(): can not open input file $fileName : $!"
			);
		}

		$outputfilename = "$fileName.pruned";

		unlink $outputfilename;

		if ( !open( OUTPUT, ">>$outputfilename" ) ) {

			logEvent( 2,
"Error 2 occured in pruneFile4(): can not open output file $fileName : $!"
			);
		}

		while ( my $line = <INPUT> ) {

			$lineCounter++;

			if (   ( $lineCounter < $check4StartLineNumber )
				|| ( $lineCounter > $check4EndLineNumber ) )
			{

				print OUTPUT "$line";

			}

		}

		close(OUTPUT);

		close(INPUT);

	}

	sub getMibSectionInfo1 {
		my ($lineNumber) = @_;
		my $returnValue = "not_found";

		for ( my $i = 0 ; $i < scalar(@mibSections1_StartLines) ; $i++ ) {

			if (   ( @mibSections1_StartLines[$i] <= $lineNumber )
				&& ( @mibSections1_EndLines[$i] >= $lineNumber ) )
			{
				$returnValue =
"#$i @mibSections1_Titles[$i] on lines @mibSections1_StartLines[$i] - @mibSections1_EndLines[$i], md5 @mibSections1_MD5Checksums[$i]";

				$i = scalar(@mibSections1_StartLines);

			}

		}

		return $returnValue;

	}

	sub getMibSectionIndex1 {
		my ($lineNumber) = @_;
		my $returnValue = -1;

		for ( my $i = 0 ; $i < scalar(@mibSections1_StartLines) ; $i++ ) {

			if (   ( @mibSections1_StartLines[$i] <= $lineNumber )
				&& ( @mibSections1_EndLines[$i] >= $lineNumber ) )
			{
				$returnValue = $i;

				$i = scalar(@mibSections1_StartLines);

			}

		}

		return $returnValue;

	}

	sub getMibSectionInfo2 {
		my ( $lineNumber, $masterFileCurrentLineId ) = @_;
		my $returnValue = "not_found";
		my $equalNote;
		my $masterFileCurrentMIBId;

		for ( my $i = 0 ; $i < scalar(@mibSections2_StartLines) ; $i++ ) {

			if (   ( @mibSections2_StartLines[$i] <= $lineNumber )
				&& ( @mibSections2_EndLines[$i] >= $lineNumber ) )
			{

				$masterFileCurrentMIBId =
				  getMibSectionIndex1($masterFileCurrentLineId);

				if ( @mibSections2_MD5Checksums[$i] eq
					@mibSections1_MD5Checksums[$masterFileCurrentMIBId] )
				{
					$equalNote = "!EQUAL TO MASTER!";
				}

				$returnValue =
"#$i $masterFileCurrentMIBId @mibSections2_Titles[$i] on lines @mibSections2_StartLines[$i] - @mibSections2_EndLines[$i], md5 @mibSections2_MD5Checksums[$i] $equalNote";

				$i = scalar(@mibSections2_StartLines);

			}

		}

		return $returnValue;

	}

	sub fnCheck1 {

		pruneFile2( $check1MasterFile, 1, 1 )
		  ;    # load mib sections map for later reference

		pruneFile2( $check1MasterFile, 1, 2 )
		  ;    # load mib sections map for later reference

## check for duplicities within the master file itself
		logEvent( 1,
"Detecting duplicities within $check1MasterFile (master file & reference file)"
		);

		pruneFile1( $check1MasterFile, 1 );

		logEvent( 1,
"Finished, total records: $recordsCounter , duplicated records: $duplicateCounter\n"
		);

## check for duplicities within reference file (optional)

		if ( $check1SecondaryFile ne "" ) {

			$recordsCounter   = 0;
			$duplicateCounter = 0;

			@mibSections2_StartLines   = ();
			@mibSections2_EndLines     = ();
			@mibSections2_Titles       = ();
			@mibSections2_MD5Checksums = ();

			pruneFile2( $check1SecondaryFile, 1, 2 );

			logEvent( 1,
"Detecting duplicities. Master file: $check1MasterFile, reference file: $check1SecondaryFile"
			);

			pruneFile1( $check1SecondaryFile, 2 );

			logEvent( 1,
"Finished, total records: $recordsCounter , duplicated records: $duplicateCounter"
			);

		}

	}

	sub fnCheck2 {

		pruneFile2( $check2MasterFile, 0 );

		logEvent( 1, "Finished, total records: $recordsCounter" );

	}

	sub fnCheck3 {

		pruneFile3($check3MasterFile);

	}

	sub fnCheck4 {

		pruneFile4($check4MasterFile);

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
}
