#!/usr/bin/perl
#### Zabbix Proxy Internal Monitoring Common Utils
#### Version 1.6
#### Writen by: Premysl Botek (pbotek@harbourmsp.com)
##################################################################################
#### Execution Requirements:
#### * All non-default Perl modules installed from section "use" below (i.e $ yum install perl-Config-Simple perl-Time-HiRes etc.)
#### * Correct paths and filenames in $logfilename, $zabbixAgentConfigFile and $systemHostsFile
#### * Log file on $logfilename must exist and zabbix user must have write right to it
##################################################################################

## pragmas, global variable declarations, environment setup

use strict;
use Config::Simple;
use Data::Dumper;
use File::Find;
use File::Basename;
use Switch;
use Time::Piece;
use Time::Seconds;
use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);

my $loggingLevel = 2
  ; # 0 - no logging, 1 - log errors only, 2 - log everything (errors, warnings, debug info)
my $logOutput = 2
  ; # 1 - output to console, 2 - output to log file, 3 - output to both console and log file

my $thisModuleID = "ZPIMCU";  # just for log file record identification purposes

my $appMode = 0
  ; # 1 - check1: check vmware_$1.txt files age, 2 - check2: measure agent item retrieval latency, 3 - check3: checks how many host names in zabbix_agentd.conf parameter Server, are not resolved locally,  4 - check4: measure zabbix_send trap latency

our $logfilename =
  "/var/log/zabbix/zproxinternalmonitoringcommonutils.log"
  ;    # file must exist and zabbix user must have write rights to it
my $zabbixAgentConfigFile = '/etc/zabbix/zabbix_agentd.conf';
my $systemHostsFile       = '/etc/hosts';

my $cmdParam1;

my $returnValue;
my $invalidCommandLine = 1;

my $check1Result;
my $check1BaseDir = "/tmp";

my %check3HostsEntries;

## program entry point
## program initialization

if ( ( scalar @ARGV ) < 1 ) {
	$invalidCommandLine = 1;
}
else {

	$invalidCommandLine = 1;

	switch ( uc( $ARGV[0] ) ) {
		case ("CHECK1") {

			$appMode            = 1;
			$invalidCommandLine = 0;

		}

		case ("CHECK2") {

			$appMode            = 2;
			$invalidCommandLine = 0;

		}

		case ("CHECK3") {

			$appMode            = 3;
			$invalidCommandLine = 0;

		}

		case ("CHECK4") {

			$appMode            = 4;
			$invalidCommandLine = 0;

		}

	}
}

if ($invalidCommandLine) {

	my $commandline = join " ", $0, @ARGV;

	print <<USAGELABEL;
Invalid command line parameters
	

USAGELABEL

	exit 0;
}

## main execution block

switch ($appMode) {

	case (1) {

		fnCheck1();
	}

	case (2) {

		fnCheck2();
	}

	case (3) {

		fnCheck3();
	}

	case (4) {

		fnCheck4();
	}

}

## end - main execution block

##  program exit point	###########################################################################

sub fnCheck3 {
	my $unmatchedHostnamesFound = 0;

	# read all host names from /etc/hosts

	open( INPUT, $systemHostsFile )
	  or ( logEvent( 2, "Input file $systemHostsFile not found.\n" )
		&& return -1 );

	while ( my $line = <INPUT> ) {

		chomp($line);
		$line =~ s/\t/ /g;    # replace tabs by spaces for easier processing

		my @items = split( /\s+/, $line );

		for ( my $i = 1 ; $i < scalar(@items) ; $i++ ) {
			$check3HostsEntries{ @items[$i] } = 1;
		}
	}
	close(INPUT);

	# read entries from Agent Config File and find match

	my $configFile = new Config::Simple($zabbixAgentConfigFile);

	my @items =
	  $configFile->param('Server')
	  ;    # possible multiple values will get parsed into an array

	for ( my $i = 0 ; $i < scalar(@items) ; $i++ ) {

		if ( !defined( $check3HostsEntries{ @items[$i] } ) ) {
			$unmatchedHostnamesFound++;
			logEvent( 2,
"Host @items[$i] from $zabbixAgentConfigFile parameter Server, is not locally resolved via $systemHostsFile"
			);

		}
	}
	print $unmatchedHostnamesFound;
}

sub fnCheck2 {

	my @output;
	my $cmd1 = "zabbix_get -s$ARGV[1] -p10050 -k\"agent.version\" 2>&1";
	my $reachedTimeout = 0;

	my $configFile = new Config::Simple($zabbixAgentConfigFile);
	my $timeout1   = $configFile->param('Timeout');
	if ( int($timeout1) < 1 ) {
		$timeout1 = 1;
	}

	#print "cmd1: $cmd1\n";

	my $timeout2 =
	  ( $timeout1 * 1_000_000 ) -
	  100_000;    # convert to microseconds and shrink by 0.1 second

	my $t0 = int( gettimeofday() * 1000 );

	eval {
		local $SIG{ALRM} = sub { die "alarm\n" };    # NB: \n required
		ualarm($timeout2);

		@output = `$cmd1`;                           # execute shell command

		ualarm 0;
	};

	if ($@) {
		if ( $@ eq "alarm\n" ) {
			$reachedTimeout = 1;
		}
		else {

			print "$@";
		}
	}
	else {

	}

	my $t1 = int( gettimeofday() * 1000 );

	my $commandResult = $output[0];
	chomp($commandResult);

	logEvent( 1, "Command return value: $commandResult" );

	#print "commandResult: $commandResult\n";
	#print "ARGV[2]: $ARGV[2]\n";

	if ( $reachedTimeout == 1 ) {
		print $timeout1* 1000;
	}
	else {

		if ( $commandResult eq $ARGV[2] ) {

			print( $t1 - $t0 );
		}
		else { print "-1"; }
	}
}

sub fnCheck1 {

	find( \&traverseDirectoryCheck1, $check1BaseDir );

	if ( !defined($check1Result) ) {
		$check1Result = "_none_";
	}

	print $check1Result;

}

sub traverseDirectoryCheck1 {

	my $fullFileName = File::Spec->rel2abs($_);
	my ( $fileName, $filePath, $suffix ) = fileparse($fullFileName);

	if ( $fileName =~ m/^vmware_\S*.txt$/ ) {

		my (
			$device, $inode, $mode,  $nlink, $uid,     $gid, $rdev,
			$size,   $atime, $mtime, $ctime, $blksize, $blocks
		  )
		  = stat($fullFileName);

		my $fileAge = time - $mtime;

		#print "fileAge: $fileAge\n";

		if ( $fileAge > 0 ) {

			if ( !defined($check1Result) ) {

				$check1Result = $fileName . " is $fileAge seconds old";

			}
			else {

				$check1Result =
				  $check1Result . "; " . $fileName . " is $fileAge seconds old";

			}

		}

	}

	#	return 1;
}

sub fnCheck4 {

	my @output;

	#my $cmd1 = "zabbix_get -s$ARGV[1] -p10050 -k\"agent.version\" 2>&1";
	my $cmd1 =
	  "zabbix_sender -z localhost -s $ARGV[1] -k zpimtrappercheck2 -o 1 2>&1";
	my $reachedTimeout = 0;

	my $t0 = int( gettimeofday() * 1000 );

	@output = `$cmd1`;    # execute shell command

	logEvent( 1, "fnCheck4(): Response received (to $cmd1): ".join ( ' ,, ', @output ));

	my $t1 = int( gettimeofday() * 1000 );

	print( $t1 - $t0 );

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

	switch ($eventType) {
		case (1) {
			$eventTypeDisplay = " Debug Info : ";

			if ( $loggingLevel == 1 ) {
				return 0;
			}

		}

		case (2) {
			$eventTypeDisplay = " !ERROR! : ";
		}

		case (3) {
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
		  || ( print "Can not open logfile $logfilename : $!\n" );
		print LOGFILEHANDLE "[$thisModuleID] $timestamp$eventTypeDisplay$msg\n";
		close LOGFILEHANDLE;

	}

}
