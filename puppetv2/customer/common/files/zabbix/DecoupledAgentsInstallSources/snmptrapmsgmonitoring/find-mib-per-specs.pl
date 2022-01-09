#!/usr/bin/perl
#### Finds MIB files contaning record of specified characteristics
#### Version 2.31
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
use File::Basename;
use Switch;
use Time::Piece;
use Time::Seconds;
use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);

my $appMode = 0
  ; # 1 - check1: check vmware_$1.txt files age, 2 - check2: measure agent item retrieval latency, 3 - check3: checks how many host names in zabbix_agentd.conf parameter Server, are not resolved locally,  4 - check4: measure zabbix_send trap latency

my $snmpTranslateExecutable = "snmptranslate";

my $returnValue;
my $invalidCommandLine = 1;

my $check1BaseDir;
my $check1SearchKeyword;
my $check1FoundMatches = 0;
my $progressStringCheck1;

## program entry point
## program initialization

if ( ( scalar @ARGV ) < 2 ) {
	$invalidCommandLine = 1;
}
else {

	$invalidCommandLine = 1;

	switch ( uc( $ARGV[0] ) ) {
		case ("1") {    # search for OID - exact match

			$appMode             = 1;
			$check1SearchKeyword = $ARGV[1];
			$check1BaseDir       = $ARGV[2];
			$invalidCommandLine  = 0;

			if ( substr( $check1SearchKeyword, 0, 1 ) ne "." ) {

				print
"\n!WARNING: Your OID does not start with dot. Are you sure this is correct? \n";

			}

		}

		case ("2") {    # search for symbolic name values - "contains" match

			$appMode             = 2;
			$check1SearchKeyword = $ARGV[1];
			$check1BaseDir       = $ARGV[2];
			$invalidCommandLine  = 0;

		}

	}
}

if ($invalidCommandLine) {

	my $commandline = join " ", $0, @ARGV;

	print <<USAGELABEL;
Invalid command line parameters

USAGE: find-mib-per-specs.pl <appMode> <searchKeyword> <searchMIBPath>	

appMode = 1 : 		find MIB files that contain object record with an OID specified in searchKeyword. Exact match is required.
appMode = 2 : 		find MIB files that contain object record with a symbolic name specified in searchKeyword. Exact match isn't required, searchKeyword must be contained within symbolic name string.

NOTE1: 			this tool uses snmptranslate utility (net-snmp-utils must be installed)
NOTE2: 			searches within searchMIBPath recursively
NOTE3:			tries all files, not only those with .mib extension 

USAGELABEL

	exit 0;
}

## main execution block

if ( fnTestSNMPTranslateExecution() == 0 ) {
	print
"Snmptranslate utility can not be executed, please ensure net-snmp-utils are installed.\n";
	exit 1;
}

fnCheck1();

## end - main execution block

##  program exit point	###########################################################################

sub fnTestSNMPTranslateExecution() {
	my $resultValue = 0;
	my $stdErrBackup;
	my $stdErr;
	my $cmd1;
	my @execOutput;
	my $tmpStr1;

	# dupe STDERR, to be restored later
	open( $stdErrBackup, ">&", \*STDERR ) or do {
		print "Can't dupe STDERR:
+ $!\n";
		return $resultValue;
	};

	# close first (according to the perldocs)
	close(STDERR) or return $resultValue;

	# redirect STDERR to in-memory scalar

	open( STDERR, '>', \$stdErr ) or do {
		print "Can't redirect STDERR: $!\
+n";
		return $resultValue;
	};

	$cmd1       = "$snmpTranslateExecutable -V";
	@execOutput = `$cmd1`;                         # execute shell command

	$tmpStr1 = $?;

	#$tmpStr1    = @$stdErr[0];

	# restore original STDERR
	open( STDERR, ">&", $stdErrBackup ) or do {
		print "Can't restore STDERR: $!\
+n";
		return $resultValue;
	};

	if ( $tmpStr1 ne "-1" ) {
		$resultValue = 1;
	}

	return $resultValue;

}

sub fnCheck1 {

	if ( $appMode == 1 ) {
		print
"\nSearching for MIB files in $check1BaseDir that contain object record with OID $check1SearchKeyword :\n";
	}
	if ( $appMode == 2 ) {
		print
"\nSearching for MIB files in $check1BaseDir that contain object record with $check1SearchKeyword in symbolic name :\n";
	}

	find( \&traverseDirectoryCheck1, $check1BaseDir );

	if ( $check1FoundMatches != 1 ) {
		print "\nNo matching MIB files found.\n\n";
	}
	else {

		print "\n";
	}

	#print $check1Result;

}

sub processMIBFileCheck1 {
	my ($filePathAndName) = @_;
	my @execOutputSymbolicNames;
	my @execOutputOIDs;
	my $reportThisFile = 0;
	my $stdErrBackup;
	my $stdErr;

	# dupe STDERR, to be restored later
	open( $stdErrBackup, ">&", \*STDERR ) or do {
		print "Can't dupe STDERR:
+ $!\n";
		exit;
	};

	# close first (according to the perldocs)
	close(STDERR) or die "Can't close STDERR: $!\n";

	# redirect STDERR to in-memory scalar

	open( STDERR, '>', \$stdErr ) or do {
		print "Can't redirect STDERR: $!\
+n";
		exit;
	};

	my $cmd1 = "$snmpTranslateExecutable -To -m $filePathAndName";
	@execOutputOIDs = `$cmd1`;    # execute shell command
	chomp(@execOutputOIDs);

	if ( $stdErr ne "" ) {

		#print "Error 1 occured in processMIBFileCheck2(): $stdErr"; exit;
		#exit;
		return 0;
	}

	my $cmd1 = "$snmpTranslateExecutable -Ts -m $filePathAndName";
	@execOutputSymbolicNames = `$cmd1`;    # execute shell command
	chomp(@execOutputSymbolicNames);

	if ( $stdErr ne "" ) {

		#print "Error 1 occured in processMIBFileCheck2(): $stdErr"; exit;
		#exit;
		return 0;
	}

	# restore original STDERR
	open( STDERR, ">&", $stdErrBackup ) or do {
		print "Can't restore STDERR: $!\
+n";
		exit;
	};

	#print Dumper(@execOutputOIDs);

	if ( $appMode == 1 ) {

		for ( my $i = 0 ; $i < scalar(@execOutputOIDs) ; $i++ ) {

			if ( @execOutputOIDs[$i] eq $check1SearchKeyword ) {

				print
"\n* Found match in $filePathAndName : @execOutputOIDs[$i] : @execOutputSymbolicNames[$i]\n";
				$check1FoundMatches = 1;
			}

		}

	}

	if ( $appMode == 2 ) {

		for ( my $i = 0 ; $i < scalar(@execOutputSymbolicNames) ; $i++ ) {

			if ( @execOutputSymbolicNames[$i] =~ /$check1SearchKeyword/ ) {

				print
"\n* Found match in $filePathAndName : @execOutputOIDs[$i] : @execOutputSymbolicNames[$i]\n\n";
				$check1FoundMatches = 1;

			}

		}

	}

}

sub traverseDirectoryCheck1 {

	my $fullFileName = File::Spec->rel2abs($_);
	my ( $fileName, $filePath, $suffix ) = fileparse($fullFileName);

	# if ( $fileName =~ m/^vmware_\S*.txt$/ ) {

	my (
		$device, $inode, $mode,  $nlink, $uid,     $gid, $rdev,
		$size,   $atime, $mtime, $ctime, $blksize, $blocks
	  )
	  = stat($fullFileName);

	my $fileAge = time - $mtime;

	#print "fileAge: $fileAge\n";

	processMIBFileCheck1($fullFileName);

	#}

	#	return 1;
}

