#!/usr/bin/perl
#### Zabbix Proxy API (Zabbix host management tool, for proxy 2.0)
#### Version 1.10
#### Written by: Premysl Botek (premysl.botek@lab.com)
##################################################################################
#### Execution Requirements:
#### perl-DBD-SQLite perl-DBI perl-Switch perl-Time-Piece perl-Config-Simple perl-Data-Dumper perl-Config-IniFiles perl-JSON
##################################################################################
#
#
#

## pragmas, global variable declarations, environment setup

use v5.10;
use strict;
use warnings;
use Switch;
use Time::Piece;
use Time::Seconds;
use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);

use FindBin '$Bin';
use Data::Dumper;
no if $] >= 5.018, warnings => "experimental::smartmatch";
#use Config::IniFiles;
use JSON;
use DBI;

# DEPENDENT SETTINGS (values need to be reverified/set correctly during each installation - for this script to work and be integrated with the rest of functionality)

my $loggingLevel = 1
  ; # 0 - no logging, 1 - log errors only, 2 - log errors + warnings, 3 - log errors + warnings + information, 4 - log everything (errors + warnings + information + debug info)
my $logOutput = 2
  ; # 1 - output to console, 2 - output to log file, 3 - output to both console and log file

our $baseDir     = $Bin;
our $logFileName = "$baseDir/log.txt";

our $systemTempDir               = "/tmp";
our $zabbixProxyDatabaseFileName = "$systemTempDir/zabbix_proxy_db/proxy.db";
my $dbhZabbixProxyDatabase;

## End - DEPENDENT SETTINGS

my $thisModuleID =
  "ZABBIX-PROXY-API-SERVER";  # just for log file record identification purposes

my $appMode      = 0;
my $invalidInput = 1;

my $jsonResponse;

my $jsonResponse_OpResult =
  -1;    # -1 unknown, 0 , 1 - OK,  2 - invalid input data, 3 - runtime error
my $jsonResponse_ErrorMessage = "";
my %jsonResponse_Data         = ();

# program entry point

main();

$jsonResponse = {
	response => {
		opresult      => $jsonResponse_OpResult,
		error_message => $jsonResponse_ErrorMessage,
		data          => \%jsonResponse_Data,
	},
	api_version => 1,
};

print encode_json($jsonResponse) . "\n";

##  program exit point

#  service functions ###########################################################################

sub main {
	my $subResult  = 0;
	my $callResult = 0;
	my $json1;

## program initialization

	#my $commandline = join " ", $0, @ARGV;
	#logEvent( 4, "Used command line: $commandline" );

	eval {

		my $old_fh = select(STDOUT);
		$| = 1;
		select($old_fh);

## main execution block

		my $remoteCmd = <STDIN>;

		eval {

			$json1 = from_json($remoteCmd);
		};

		if ($@) {
			$jsonResponse_OpResult = 2;
			$jsonResponse_ErrorMessage =
"Error 2 occured in main(). Invalid input JSON. Runtime error message: $@  Received data: "
			  . $remoteCmd;

			logEvent( 1, $jsonResponse_ErrorMessage );

			return $subResult;

		}

		given ( $json1->{'request'}->{'cmd'} ) {

			when ("1") {

				$appMode      = 1;
				$invalidInput = 0;

			}

		}

		logEvent( 4, "cmd data: " . $remoteCmd );

		if ( $invalidInput == 1 ) {
			$jsonResponse_OpResult = 2;
			$jsonResponse_ErrorMessage =
			  "Invalid input params. Received data:  " . Dumper($json1);
			logEvent( 1, $jsonResponse_ErrorMessage );
			return $subResult;

		}

####

		given ($appMode) {

			when (1) {
				$callResult = FetchProxyDBIPtoHostMappings();

			}

		}

####

## end - main execution block

		if ( $callResult == 1 ) {
			$subResult                 = 1;
			$jsonResponse_OpResult     = 1;
			$jsonResponse_ErrorMessage = "";

		}
	};
	if ($@) {

		$jsonResponse_OpResult     = 3;
		$jsonResponse_ErrorMessage = "Error 1 occured in main(): $@";

		logEvent( 1, $jsonResponse_ErrorMessage );

	}

	return $subResult;

}

sub logEvent {    # method Version: 5
	my ( $eventType, $msg ) =
	  @_;    # event type: 1 - error, 2 - warning, 3 - information, 4 - debug

	my ( $s, $usec ) = gettimeofday();    # get microseconds haha
	my $timestamp = localtime->strftime("%Y-%m-%d %H:%M:%S.") . ($usec);

	my $eventTypeDisplay = "";

	if ( ( $loggingLevel == 0 ) || ( $logOutput == 0 ) ) {
		return 0;
	}

	if ( $loggingLevel < $eventType ) {
		return 0;
	}

	given ($eventType) {
		when (1) {
			$eventTypeDisplay = " !ERROR! : ";
		}

		when (2) {
			$eventTypeDisplay = " Warning : ";

		}

		when (3) {
			$eventTypeDisplay = " Information : ";

		}

		when (4) {
			$eventTypeDisplay = " Debug Info : ";

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

sub FetchProxyDBIPtoHostMappings {
	my $subResult = 0;
	my $sql1;
	my $sth1;
	my %jsonResponse_Data_HostInfo      = ();
	my %jsonResponse_Data_InterfaceInfo = ();

	eval {
		# connect to zabbix proxy database

		if ( !-f $zabbixProxyDatabaseFileName ) {

			$jsonResponse_OpResult = 3;
			$jsonResponse_ErrorMessage =
			  "Database file $zabbixProxyDatabaseFileName does not exist";

			logEvent( 1, $jsonResponse_ErrorMessage );

			return $subResult;
		}

		$dbhZabbixProxyDatabase = DBI->connect(
			"dbi:SQLite:dbname=$zabbixProxyDatabaseFileName",
			"", "", { PrintError => 0, RaiseError => 1 }
			, # RaiseError  => 0 - throw catchable exception, PrintError=>0 - do not print warnings/error
		  )

		  or

		  (

			$jsonResponse_OpResult = 3
			&& $jsonResponse_ErrorMessage =
"Error 2 occured in FetchProxyDBIPtoHostMappings(): Can't open database: $DBI::errstr"
			&&

			logEvent( 1, $jsonResponse_ErrorMessage ) && return $subResult
		  );

## load host info

		$sql1 = "SELECT hostid,host FROM hosts";
		$sth1 = $dbhZabbixProxyDatabase->prepare($sql1);
		$sth1->execute();

		while ( my @rowArray1 = $sth1->fetchrow_array() ) {

			my $jsonResponse_Data_HostInfo_Item = {
				hostid => $rowArray1[0],
				host   => $rowArray1[1],
			};

			#	push @{ $jsonResponse_Data_HostInfo{hosts} },
			#	  $jsonResponse_Data_HostInfo_Item;

			push @{ $jsonResponse_Data{hosts} },
			  $jsonResponse_Data_HostInfo_Item;

		}

		#push @{ $jsonResponse_Data{data} }, \%jsonResponse_Data_HostInfo;

## load interface info

		$sql1 = "SELECT hostid,ip FROM interface";

		$sth1 = $dbhZabbixProxyDatabase->prepare($sql1);
		$sth1->execute();

		while ( my @rowArray1 = $sth1->fetchrow_array() ) {

			my $jsonResponse_Data_InterfaceInfo_Item = {
				hostid => $rowArray1[0],
				ip     => $rowArray1[1],
			};

			#push @{ $jsonResponse_Data_InterfaceInfo{interfaces} },
			#  $jsonResponse_Data_InterfaceInfo_Item;
			push @{ $jsonResponse_Data{interfaces} },
			  $jsonResponse_Data_InterfaceInfo_Item;

		}

		#push @{ $jsonResponse_Data{data} }, \%jsonResponse_Data_InterfaceInfo;

##

		logEvent( 3, "JSON: " . encode_json( \%jsonResponse_Data ) );

		$sth1->finish();  # end statement, release resources (not a transaction)

		$dbhZabbixProxyDatabase = undef;

##

		$subResult = 1;

	};
	if ($@) {

		$jsonResponse_OpResult = 3;
		$jsonResponse_ErrorMessage =
		  "Error 1 occured in FetchProxyDBIPtoHostMappings(): $@";

		logEvent( 1, $jsonResponse_ErrorMessage );
		return $subResult;

	}

	return $subResult;

}

