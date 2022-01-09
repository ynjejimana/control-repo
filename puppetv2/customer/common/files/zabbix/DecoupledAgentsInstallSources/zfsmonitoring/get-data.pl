#!/usr/bin/perl
#### Monitoring Oracle ZFS Storage (RESTful service querying utility for automated Zabbix information retrieval)
#### Version 1.62
#### Written by: Premysl Botek (premysl.botek@lab.com)
##################################################################################
#### Execution Requirements:
#### * All non-default Perl modules listed as "use" from section "pragmas ..." below (i.e $ yum install perl-Time-HiRes perl-Net-SNMP, $ cpan Config::Std etc.)
##################################################################################
#
#
#

## pragmas, global variable declarations, environment setup

use v5.10;
use strict;
no if $] >= 5.018, 'warnings', "experimental::smartmatch";
use Data::Dumper;
use Time::Piece;
use Time::Seconds;
use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);
use threads;
use threads::shared;
use REST::Client;
use JSON;
use MIME::Base64;
use DBI;
use DBD::SQLite;

#no warnings 'threads';

# DEPENDENT SETTINGS (values need to be reverified/set correctly during each installation - for this script to work and be integrated with the rest of functionality)

our $scriptsBaseDir = "/srv/zabbix/scripts/zfsmonitoring";
our $logFileName    = "$scriptsBaseDir/log.txt";

my $loggingLevel = 1
  ; # 0 - no logging, 1 - log errors only, 2 - log everything (errors, warnings, debug info)
my $logOutput = 2
  ; # 1 - output to console, 2 - output to log file, 3 - output to both console and log file
my $restfulClientRequestsTimeout = 20;
;    # timeout of RESTful client requets [seconds].

my $zpimZAgentPerf1TracingEnabled = 0;
my $zpimBaseDir                   = "/srv/zabbix/scripts/zpimonitoring";

## End - DEPENDENT SETTINGS

my $thisModuleID =
  "GET-DATA";    # just for log file record identification purposes

#my $returnValue;

my $localDatabaseFileName = "$scriptsBaseDir/zfsmonitoringdata.db";
my $localDatabaseDBH;

my $zpimDatabase1FileName = "$zpimBaseDir/zpimonitoring.db";
my $zpimZAgentPerf1Tracing_ZFSMonitoringGetDataAnchor1_GUID =
  'ae579f42-0afa-4409-b79e-45e0f790e029';
my $zpimZAgentPerf1Tracing_ZFSMonitoringGetDataAnchor1_TimeStamp0;

my $appMode = 0;

my $httpCacheMaximumContentAge = 30
  ; # maximum age of valid content in the HTTP cache [seconds]. After that period, content is considered stale

my $invalidCommandLine = 0;

my $scriptLogFileErrorsCount;

my $zabbixAgentTimeout = 30
  ; #[seconds]. Must be used the lower value from zabbix_agentd.conf and zabbix_proxy.conf. Signifies time after which the worker process gets killed unless it finishes voluntarily

## program entry point

main();

##  program exit point	###########################################################################

sub main {

	my $returnValue;

	## program initialization

	my $commandline = join " ", $0, @ARGV;
	logEvent( 1, "Used command line: $commandline" );

	if ( scalar(@ARGV) < 1 ) {
		$invalidCommandLine = 1;
	}
	else {

		$invalidCommandLine = 1;

		given ( uc( $ARGV[0] ) ) {

			when ("1") {

				$appMode            = 1;
				$invalidCommandLine = 0;
			}

			when ("2") {

				$appMode            = 2;
				$invalidCommandLine = 0;

			}

			when ("3") {

				$appMode            = 3;
				$invalidCommandLine = 0;

			}

			when ("4") {

				$appMode            = 4;
				$invalidCommandLine = 0;

			}

		}

	}

	if ($invalidCommandLine) {

		my $commandline = join " ", $0, @ARGV;
		logEvent( 2, "Invalid command line: $commandline" );

		print <<USAGELABEL;
Invalid command line parameters
	
USAGE:		perl get-data.pl <cmdID> ...
	
* when cmdId is 1, remaining parameters are: <itemOIDprefix> <itemOIDIndex> <Host> <SNMPCommunity> <SNMPVersion> [zabbixHostNameReference] - Executes the specified SNMP query and returns its result. ZabbixHostNameReference is used only for debugging reasons - to identify in the log file where SNMP requests come from. 

1 DATASETS /api/analytics/v1/datasets/cpu.utilization/data https root sun123 10.12.7.17 215 monitoredhost1


 
* when cmdId is 2 - Returns 'none' or number of errors recorded in the script's .log file (shared by all scripts).
	
LOGGING:	set \$loggingLevel variable : 0 - no logging, 1 - log errors only, 2 - log everything (errors, warnings, debug info)

		set \$logOutput variable : 1 - output to console, 2 - output to log file, 3 - output to both console and log file
	
USAGELABEL

		exit 0;
	}

## main execution block

	# add anchor record to the internal monitoring db
	zpimZAgentPerf1Entry(
		1,
		$zpimZAgentPerf1Tracing_ZFSMonitoringGetDataAnchor1_GUID,
		\$zpimZAgentPerf1Tracing_ZFSMonitoringGetDataAnchor1_TimeStamp0,
		$$,
		$commandline,
		undef
	);

	given ($appMode) {

		when (1) {

			$returnValue = fnRESTFULSingleItemRequest1(
				$ARGV[1], $ARGV[2], $ARGV[3], $ARGV[4],
				$ARGV[5], $ARGV[6], $ARGV[7]
			);
			if ( defined($returnValue) ) {

				print $returnValue

			}

		}

		when (2) {
			print fnGetScriptLogFileErrorCount();

		}

		when (3) {

			$returnValue = fnRESTFULSingleItemRequest2(
				$ARGV[1], $ARGV[2], $ARGV[3], $ARGV[4],
				$ARGV[5], $ARGV[6], $ARGV[7], $ARGV[8]
			);
			if ( defined($returnValue) ) {

				print $returnValue

			}

		}

		when (4) {

			$returnValue = fnRESTFULSingleItemRequest3(
				$ARGV[1], $ARGV[2], $ARGV[3], $ARGV[4],
				$ARGV[5], $ARGV[6], $ARGV[7], $ARGV[8]
			);
			if ( defined($returnValue) ) {

				print $returnValue

			}

		}

	}

	# remove anchor record from the internal monitoring db
	zpimZAgentPerf1Entry(
		2,
		$zpimZAgentPerf1Tracing_ZFSMonitoringGetDataAnchor1_GUID,
		\$zpimZAgentPerf1Tracing_ZFSMonitoringGetDataAnchor1_TimeStamp0,
		$$,
		undef,
		$returnValue
	);

## end - main execution block

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

sub fnRESTFULSingleItemRequest1 {    #
	my (
		$restfulHostAddress,  $restfulUsername,  $restfulPassword,
		$zabbixHostReference, $restfulPathPart1, $restfulPathPart2,
		$restfulPathPart3
	  )
	  = @_;
	my $restfulHeaders;
	my $restfulClient;
	my $restfulPath;
	my $restfulResponse;
	my $httpCacheResponse;
	my $resultValue;

	eval {

		## connect to database

		if ( !-f $localDatabaseFileName ) {
			logEvent( 2,
				"Database file $localDatabaseFileName does not exist" );
			return $resultValue;
		}

		$localDatabaseDBH = DBI->connect(
			"dbi:SQLite:dbname=$localDatabaseFileName",
			"", "", { RaiseError => 1 },
		);

	};

	if ($@) {
		logEvent( 2, "Error 1 occured in fnRESTFULSingleItemRequest1(): $@" );
		return $resultValue;
	}

##

	$restfulPath =
	  $restfulPathPart1 . $restfulPathPart2 . $restfulPathPart3 . '/data';

	$httpCacheResponse = fnQueryHTTPCache( $restfulHostAddress . $restfulPath );
	if ( defined($httpCacheResponse) ) {

		eval {

			$restfulResponse = from_json($httpCacheResponse);

			$resultValue = $restfulResponse->{'data'}->{'data'}->{'value'};

			logEvent( 1,
				    "Response Value (retrieved from cache): "
				  . $resultValue
				  . " URL: "
				  . $restfulHostAddress
				  . $restfulPath );

		};
		if ($@) {
			logEvent( 2,
				"Error 2 occured in fnRESTFULSingleItemRequest1(): $@" );
			return $resultValue;
		}

	}

	else {

		$restfulHeaders = {
			Accept        => 'application/json',
			Authorization => 'Basic '
			  . encode_base64( $restfulUsername . ':' . $restfulPassword ),

	               };
                        
                        


		$restfulClient = REST::Client->new(
			{
				host    => $restfulHostAddress,
				timeout => $restfulClientRequestsTimeout,
			}
		);

		logEvent( 1, "RESTful request: $restfulHostAddress$restfulPath" );

		fnManageHTTPCache( 1, $restfulHostAddress . $restfulPath, undef );

		$restfulClient->GET( $restfulPath, $restfulHeaders );

		if ( $restfulClient->responseCode() ne "200" ) {

			my $errorDescAppendix = "";

			if ( $restfulClient->responseCode() eq "500" ) {
				$errorDescAppendix =
" This is most likely caused by response timeout (\$restfulClientRequestsTimeout=$restfulClientRequestsTimeout sec.).";

			}

			logEvent( 2,
"Error 3 in fnRESTFULSingleItemRequest1(). RESTful client ($restfulPath) returned HTTP response code "
				  . $restfulClient->responseCode() . "."
				  . $errorDescAppendix );

			fnManageHTTPCache( 3, $restfulHostAddress . $restfulPath, undef );

		}
		else {

			eval {

				#	print Dumper($restfulResponse);

				fnManageHTTPCache(
					2,
					$restfulHostAddress . $restfulPath,
					$restfulClient->responseContent()
				);

				$restfulResponse =
				  from_json( $restfulClient->responseContent() );

				my $restfulResponseDataValue =
				  $restfulResponse->{'data'}->{'data'}->{'value'};

				$resultValue = $restfulResponseDataValue;

				logEvent( 1,
					    "Response Value (retrieved from host): "
					  . $resultValue
					  . " URL: "
					  . $restfulHostAddress
					  . $restfulPath );

			};
			if ($@) {
				logEvent( 2,
					"Error 4 occured in fnRESTFULSingleItemRequest1(): $@" );
				return $resultValue;
			}

		}

	}

##

	eval {

		undef $localDatabaseDBH;

	};

	if ($@) {
		logEvent( 2, "Error 5 occured in fnRESTFULSingleItemRequest1(): $@" );
		return $resultValue;
	}

	return $resultValue;

}

sub fnQueryHTTPCache {
	my ($restfulURL) = @_;

	my $resultValue;
	my $waitForOtherInstanceDownload = 0;

	#logEvent( 1, "fnQueryHTTPCache() - URL: " . $restfulURL );

##	maintain cache

# delete all "download pending" records that have not returned (killed by zagent). Those records would block workers that wait for the download of content for the same URL

	eval {

		my $sql1 =
"DELETE FROM TA_HTTP_CACHE WHERE DL_STATE=1 AND DATETIME(DT_TIMESTAMP)<DATETIME(DATETIME( 'now' , 'localtime' ),'-"
		  . $zabbixAgentTimeout
		  . " second')";

		my $sth = $localDatabaseDBH->prepare($sql1);

		$sth->execute();

		$sth->finish();

	};

	if ($@) {
		logEvent( 2, "Error 1 occured in fnQueryHTTPCache(): $@" );
		return $resultValue;
	}

##

	eval {

		do {
			my $sql1 =
"SELECT DS_CONTENT,DL_STATE FROM TA_HTTP_CACHE WHERE DS_URL=? AND DATETIME(DT_TIMESTAMP)>DATETIME(DATETIME( 'now' , 'localtime' ),'-"
			  . $httpCacheMaximumContentAge
			  . " second')";

			#logEvent( 1, "fnQueryHTTPCache() - SQL: " . $sql1 );

			my $sth = $localDatabaseDBH->prepare($sql1);

			$sth->execute($restfulURL);

			my @rowArray;

			@rowArray = $sth->fetchrow_array();

			$sth->finish();

			#logEvent( 1, "fnQueryHTTPCache(): rowArray[1]".@rowArray[1] );

			if ( defined( @rowArray[1] ) ) {    # matching URL record was found

				given ( @rowArray[1] ) {

					when (1)
					{ # our content is being downloaded by another instance : wait
						usleep( 100 * 1000 );
						$waitForOtherInstanceDownload = 1;

					}

					when (2) {    # our content is ready for use : read it
						$resultValue                  = @rowArray[0];
						$waitForOtherInstanceDownload = 0;

				#logEvent( 1, "fnQueryHTTPCache(): successful HTTP cache hit" );
					}

					default {     # all other cases
						$waitForOtherInstanceDownload = 0;

					  }

				}

			}
			else {                # no matching URL record was found

				$waitForOtherInstanceDownload = 0;

			  #logEvent( 1, "fnQueryHTTPCache(): unsuccessful HTTP cache hit" );

			}

#logEvent( 1, "fnQueryHTTPCache(): waitForOtherInstanceDownload: ".$waitForOtherInstanceDownload );

		} while ( $waitForOtherInstanceDownload != 0 );

	};

	if ($@) {
		logEvent( 2, "Error 2 occured in fnQueryHTTPCache(): $@" )
		  ;
		return $resultValue;
	}

	return $resultValue;

}

sub fnManageHTTPCache {
	my ( $opCode, $restfulURL, $restfulContent ) = @_;

	my $resultValue;

	logEvent( 1, "fnManageHTTPCache() opCode: " . $opCode );

##
	if ( $opCode == 1 )
	{    # insert a new URL record to notify that content is being downloaded

		eval {

			my $sql1 = "DELETE FROM TA_HTTP_CACHE WHERE DS_URL=?";

			my $sth = $localDatabaseDBH->prepare($sql1);

			$sth->execute($restfulURL);

			$sth->finish();

		};

		if ($@) {
			logEvent( 2, "Error 1 occured in fnManageHTTPCache(): $@" );
			return $resultValue;
		}

		eval {

			my $sql1 =
			  "INSERT INTO TA_HTTP_CACHE (DL_STATE,DS_URL) VALUES (1,?)";

			my $sth = $localDatabaseDBH->prepare($sql1);

			$sth->execute($restfulURL);

			$sth->finish();

		};

		if ($@) {
			logEvent( 2, "Error 2 occured in fnManageHTTPCache(): $@" );
			return $resultValue;
		}

	}

##

	if ( $opCode == 2 )
	{ # insert successfuly downloaded content to the previously created URL record

		eval {

			my $sql1 =
"UPDATE TA_HTTP_CACHE SET DL_STATE=2,DT_TIMESTAMP=datetime('now','localtime'),DS_CONTENT=? WHERE DS_URL=?";

			my $sth = $localDatabaseDBH->prepare($sql1);

			$sth->execute( $restfulContent, $restfulURL );

			$sth->finish();

		};

		if ($@) {
			logEvent( 2, "Error 3 occured in fnManageHTTPCache(): $@" );
			return $resultValue;
		}

	}

##

	if ( $opCode == 3 )
	{    # content download has failed - delete previously created URL record

		eval {

			my $sql1 = "DELETE FROM TA_HTTP_CACHE WHERE DS_URL=?";

			my $sth = $localDatabaseDBH->prepare($sql1);

			$sth->execute($restfulURL);

			$sth->finish();

		};

		if ($@) {
			logEvent( 2, "Error 4 occured in fnManageHTTPCache(): $@" );
			return $resultValue;
		}

	}

	return $resultValue;

}

sub fnRESTFULSingleItemRequest2 {
	my (
		$restfulHostAddress,  $restfulUsername,  $restfulPassword,
		$zabbixHostReference, $restfulPathPart1, $restfulPathPart2,
		$restfulPathPart3,    $restfulPathPart4
	  )
	  = @_;
	my $restfulHeaders;
	my $restfulClient;
	my $restfulPath;
	my $restfulResponse;
	my $httpCacheResponse;
	my $restfulResponseDataValue;
	my $resultValue;

	eval {

		## connect to database

		if ( !-f $localDatabaseFileName ) {
			logEvent( 2,
				"Database file $localDatabaseFileName does not exist" );
			return $resultValue;
		}

		$localDatabaseDBH = DBI->connect(
			"dbi:SQLite:dbname=$localDatabaseFileName",
			"", "", { RaiseError => 1 },
		);

	};

	if ($@) {
		logEvent( 2, "Error 1 occured in fnRESTFULSingleItemRequest2(): $@" );
		return $resultValue;
	}

##

	$restfulPath = $restfulPathPart1 . "/" . $restfulPathPart2;

	$httpCacheResponse = fnQueryHTTPCache( $restfulHostAddress . $restfulPath );
	if ( defined($httpCacheResponse) ) {

		eval {

			$restfulResponse = from_json($httpCacheResponse);

			$restfulResponseDataValue =
			  $restfulResponse->{ $restfulPathPart3
			  };    # get value or pointer to another json nest level

			if ( $restfulPathPart4 ne "bogus" )
			{ # if $restfulPathPart4 parameter was defined, dig into second json nest level
				$restfulResponseDataValue =
				  $restfulResponseDataValue->{$restfulPathPart4};
			}
			else {

				$restfulResponseDataValue =
				  Dumper($restfulResponseDataValue)
				  ;    # or turn the retrieved value into scalar data

			}

			$resultValue = $restfulResponseDataValue;

			logEvent( 1,
				    "Response Value (retrieved from cache): "
				  . $resultValue
				  . " URL: "
				  . $restfulHostAddress
				  . $restfulPath );

		};
		if ($@) {
			logEvent( 2,
				"Error 2 occured in fnRESTFULSingleItemRequest2(): $@" );
			return $resultValue;
		}

	}

	else {

		$restfulHeaders = {
			Accept        => 'application/json',
			Authorization => 'Basic '
			  . encode_base64( $restfulUsername . ':' . $restfulPassword )
		};

		$restfulClient = REST::Client->new(
			{
				host    => $restfulHostAddress,
				timeout => $restfulClientRequestsTimeout,
			}
		);

		logEvent( 1, "RESTful request: $restfulHostAddress$restfulPath" );

		fnManageHTTPCache( 1, $restfulHostAddress . $restfulPath, undef );

		$restfulClient->GET( $restfulPath, $restfulHeaders );

		if ( $restfulClient->responseCode() ne "200" ) {

			my $errorDescAppendix = "";

			if ( $restfulClient->responseCode() eq "500" ) {
				$errorDescAppendix =
" This is most likely caused by response timeout (\$restfulClientRequestsTimeout=$restfulClientRequestsTimeout sec.).";

			}

			logEvent( 2,
"Error 3 in fnRESTFULSingleItemRequest2(). RESTful client ($restfulPath) returned HTTP response code "
				  . $restfulClient->responseCode() . "."
				  . $errorDescAppendix );

			fnManageHTTPCache( 3, $restfulHostAddress . $restfulPath, undef );

		}
		else {

			eval {

				fnManageHTTPCache(
					2,
					$restfulHostAddress . $restfulPath,
					$restfulClient->responseContent()
				);

				$restfulResponse =
				  from_json( $restfulClient->responseContent() );

				$restfulResponseDataValue =
				  $restfulResponse->{ $restfulPathPart3
				  };    # get value or pointer to another json nest level

				if ( $restfulPathPart4 ne "bogus" )
				{ # if $restfulPathPart4 parameter was defined, dig into second json nest level
					$restfulResponseDataValue =
					  $restfulResponseDataValue->{$restfulPathPart4};
				}
				else {

					$restfulResponseDataValue =
					  Dumper($restfulResponseDataValue)
					  ;    # or turn the retrieved value into scalar data

				}

				$resultValue = $restfulResponseDataValue;

				logEvent( 1,
					    "Response Value (retrieved from host): "
					  . $resultValue
					  . " URL: "
					  . $restfulHostAddress
					  . $restfulPath );

			};
			if ($@) {
				logEvent( 2,
					"Error 4 occured in fnRESTFULSingleItemRequest2(): $@" );
				return $resultValue;
			}

		}
	}

##

	eval {

		undef $localDatabaseDBH;

	};

	if ($@) {
		logEvent( 2, "Error 5 occured in fnRESTFULSingleItemRequest2(): $@" );
		return $resultValue;
	}

	return $resultValue;

}

# $restfulPathPart1 - complete path to restful group type 1 (e.g. "https://10.12.7.17:215/api/hardware/v1/chassis/chassis-001")
# $restfulPathPart2 - subgroup 1  (e.g. "chassis/psu") - to iterate through nested levels
# $restfulPathPart3 - subgroup 2 (e.g. "psu-000") - look for specified string in the last part of href value
# $restfulPathPart4 - value name (e.g. "manufacturer") - to look for value of a specified name
sub fnRESTFULSingleItemRequest3 {    #
	my (
		$restfulHostAddress,  $restfulUsername,  $restfulPassword,
		$zabbixHostReference, $restfulPathPart1, $restfulPathPart2,
		$restfulPathPart3,    $restfulPathPart4
	  )
	  = @_;
	my $restfulHeaders;
	my $restfulClient;
	my $restfulPath;
	my $restfulResponse;
	my $httpCacheResponse;
	my $restfulResponseDataValue;
	my $resultValue;
	my @restfulPathPart3_Parts;

	eval {

		# connect to database

		if ( !-f $localDatabaseFileName ) {
			logEvent( 2,
				"Database file $localDatabaseFileName does not exist" );
			return $resultValue;
		}

		$localDatabaseDBH = DBI->connect(
			"dbi:SQLite:dbname=$localDatabaseFileName",
			"", "", { RaiseError => 1 },
		);

	};

	if ($@) {
		logEvent( 2, "Error 1 occured in fnRESTFULSingleItemRequest3(): $@" );
		return $resultValue;
	}

##

	my @restfulPathPart3_Parts = split( '/', $restfulPathPart3 );
	$restfulPath = $restfulPathPart1 . '/' . @restfulPathPart3_Parts[0];

	$httpCacheResponse = fnQueryHTTPCache( $restfulHostAddress . $restfulPath );
	if ( defined($httpCacheResponse) ) {

		eval {

			$restfulResponse = from_json($httpCacheResponse);

			##get whole response, then narrow it down to the required nest level and value sought
			$restfulResponseDataValue = $restfulResponse;

			#dig into JSON nested levels specified by $restfulPathPart2
			my @nestLevelParts = split( '/', $restfulPathPart2 );
			for ( my $i = 0 ; $i < scalar(@nestLevelParts) ; $i++ ) {

				$restfulResponseDataValue =
				  $restfulResponseDataValue->{ @nestLevelParts[$i]
				  };    # get value or pointer to another json nest level

			}

			my $foundArrayItem;
			foreach $foundArrayItem (@$restfulResponseDataValue) {

				#print Dumper($item) . "\n\n\n\n";

				my @hrefParts = split( '/', $foundArrayItem->{'href'} );
				if ( @hrefParts[ scalar(@hrefParts) - 1 ] eq
					@restfulPathPart3_Parts[1] )
				{

					$resultValue = $foundArrayItem->{$restfulPathPart4};

					#print $resultValue . "\n";
				}

			}

			logEvent( 1,
				    "Response Value (retrieved from cache): "
				  . $resultValue
				  . " URL: "
				  . $restfulHostAddress
				  . $restfulPath );

		};
		if ($@) {
			logEvent( 2,
				"Error 2 occured in fnRESTFULSingleItemRequest3(): $@" );
			return $resultValue;
		}

	}

	else {

		$restfulHeaders = {
			Accept        => 'application/json',
			Authorization => 'Basic '
			  . encode_base64( $restfulUsername . ':' . $restfulPassword )
		};

		$restfulClient = REST::Client->new(
			{
				host    => $restfulHostAddress,
				timeout => $restfulClientRequestsTimeout,
			}
		);

		logEvent( 1, "RESTful request: $restfulHostAddress$restfulPath" );

		fnManageHTTPCache( 1, $restfulHostAddress . $restfulPath, undef );

		$restfulClient->GET( $restfulPath, $restfulHeaders );

		if ( $restfulClient->responseCode() ne "200" ) {

			my $errorDescAppendix = "";

			if ( $restfulClient->responseCode() eq "500" ) {
				$errorDescAppendix =
" This is most likely caused by response timeout (\$restfulClientRequestsTimeout=$restfulClientRequestsTimeout sec.).";

			}

			logEvent( 2,
"Error 3 in fnRESTFULSingleItemRequest3(). RESTful client ($restfulPath) returned HTTP response code "
				  . $restfulClient->responseCode() . "."
				  . $errorDescAppendix );

			fnManageHTTPCache( 3, $restfulHostAddress . $restfulPath, undef );

		}
		else {

			eval {

				fnManageHTTPCache(
					2,
					$restfulHostAddress . $restfulPath,
					$restfulClient->responseContent()
				);

				$restfulResponse =
				  from_json( $restfulClient->responseContent() );

				##get whole response, then narrow it down to the required nest level and value sought
				$restfulResponseDataValue = $restfulResponse;

				#dig into JSON nested levels specified by $restfulPathPart2
				my @nestLevelParts = split( '/', $restfulPathPart2 );
				for ( my $i = 0 ; $i < scalar(@nestLevelParts) ; $i++ ) {

					$restfulResponseDataValue =
					  $restfulResponseDataValue->{ @nestLevelParts[$i]
					  };    # get value or pointer to another json nest level

				}

				my $foundArrayItem;
				foreach $foundArrayItem (@$restfulResponseDataValue) {

					#print Dumper($item) . "\n\n\n\n";

					my @hrefParts = split( '/', $foundArrayItem->{'href'} );
					if ( @hrefParts[ scalar(@hrefParts) - 1 ] eq
						@restfulPathPart3_Parts[1] )
					{

						$resultValue = $foundArrayItem->{$restfulPathPart4};

						#print $resultValue . "\n";

					}

				}

				logEvent( 1,
					    "Response Value (retrieved from host): "
					  . $resultValue
					  . " URL: "
					  . $restfulHostAddress
					  . $restfulPath );

			};
			if ($@) {
				logEvent( 2,
					"Error 4 occured in fnRESTFULSingleItemRequest3(): $@" );
				return $resultValue;
			}

		}

	}

##

	eval {

		undef $localDatabaseDBH;

	};

	if ($@) {
		logEvent( 2, "Error 5 occured in fnRESTFULSingleItemRequest3(): $@" );
		return $resultValue;
	}

	return $resultValue;

}




# will count errors up to $scriptLogFileErrorsCountLimit but not further to not block processing of Zabbix Agent worker for too long in case of very large log files
sub fnGetScriptLogFileErrorCount {    # method Version: 3
	my $returnValue                   = -1;
	my $scriptLogFileErrorsCount      = 0;
	my $scriptLogFileErrorsCountLimit = 1000;

	if ( !open( INPUT, $logFileName ) ) {

		logEvent( 2, "Error 1 occured in fnGetScriptLogFileErrorCount(): $!" );

	}
	else {

		while (( my $line = <INPUT> )
			&& ( $scriptLogFileErrorsCount < $scriptLogFileErrorsCountLimit ) )
		{

			if ( $line =~ / !ERROR! / ) {

				$scriptLogFileErrorsCount++;

			}
		}

		close(INPUT);

		$returnValue = $scriptLogFileErrorsCount;

	}

	logEvent( 1, "Response : $returnValue" );

	return $returnValue;

}

################# - Zabbix Proxy Internal Monitoring - Common API Library ver. seq. #6

# zpimZAgentPerf1Entry: add/remove anchor record to/from the proxy internal monitoring db
# input/output parameters:
# param1: 1 - add, 2 - remove
# param2: anchor guid
# param3: reference to a timestamp that keeps time when anchor was inserted (measuring time lapsed). third parameter must be a reference - sub is going to write to it.
# param4: current process ID - identifies session ($$ gets the current process ID)
# param5: additional session parameters (command line)

sub zpimZAgentPerf1Entry {
	my ( $actionId, $functinalityGUID, $anchorTimestampRef, $sessionId, $dsVal1,
		$dsVal2
	  ) # $anchorTimestampRef is a reference - for further variable modifications
	  = # $actionId: 1 - add functionality section session anchor, 2 - remove functionality section anchor
	  @_;

	my $returnValue = 0;
	my $zpimDatabase1DBH;
	my $zpimSth1;
	my $zpimSql1;

## test if tracing is enabled
	if ( $zpimZAgentPerf1TracingEnabled != 1 ) {
		return $returnValue;
	}

	logEvent( 1, "zpimDatabase1FileName: $zpimDatabase1FileName" );

## test if internal monitoring database exists
	if ( !( -f $zpimDatabase1FileName ) ) {
		logEvent( 2, "Error 1 in zpimZAgentPerf1Entry(): $@" );
		return $returnValue;
	}

## open internal monitoring database
	eval {

		$zpimDatabase1DBH = DBI->connect(
			"dbi:SQLite:dbname=$zpimDatabase1FileName",
			"", "", { RaiseError => 1 },
		);

	};

	if ($@) {
		logEvent( 2, "Error 2 in zpimZAgentPerf1Entry(): $@" );
		return $returnValue;
	}

#### do the work

	if ( $actionId == 1 ) {    ### add a fresh anchor record

		eval {

			# delete possibly existing stale record
			$zpimSql1 = <<DELIMITER1;
		
DELETE FROM TA_ZAGENT_PERF_1
WHERE DS_FUNCTIONALITY_GUID=? AND DS_SESSION_ID=? 	
		
DELIMITER1

			$zpimSth1 = $zpimDatabase1DBH->prepare($zpimSql1);

			$zpimSth1->execute( $functinalityGUID, $sessionId );

			# insert fresh record
			$zpimSql1 = <<DELIMITER1;
		
INSERT INTO TA_ZAGENT_PERF_1 (DL_ANCHOR_STATUS,DS_FUNCTIONALITY_GUID,DS_SESSION_ID,DS_VAL1) 
VALUES (1,?,?,?)	
		
DELIMITER1

			$zpimSth1 = $zpimDatabase1DBH->prepare($zpimSql1);

			$zpimSth1->execute( $functinalityGUID, $sessionId, $dsVal1 );

		};

		if ($@) {
			logEvent( 2, "Error 3 in zpimZAgentPerf1Entry(): $@" );
			return $returnValue;
		}

		$$anchorTimestampRef =
		  int( gettimeofday() * 1000 )
		  ; # modify dereferenced global variable - get current timestamp of time when a new anchor was created

	}

	if ( $actionId == 2 ) {    ### remove anchor record

		my $anchorLapsedTime =
		  int( gettimeofday() * 1000 ) - $$anchorTimestampRef;
		eval {

## update status of anchor record (2=completed)
			$zpimSql1 = <<DELIMITER1;
				
UPDATE TA_ZAGENT_PERF_1 SET DL_ANCHOR_STATUS=2, DL_ANCHOR_DURATION=?, DS_VAL2=?  
WHERE DS_FUNCTIONALITY_GUID=? AND DS_SESSION_ID=? 
		
DELIMITER1

			$zpimSth1 = $zpimDatabase1DBH->prepare($zpimSql1);

			$zpimSth1->execute( $anchorLapsedTime, $dsVal2, $functinalityGUID,
				$sessionId );
		};

		if ($@) {
			logEvent( 2, "Error 4 in zpimZAgentPerf1Entry(): $@" );
			return $returnValue;
		}

	}

### close internal monitoring database
	eval {

		undef $zpimDatabase1DBH;

	};
	if ($@) {

		logEvent( 2, "Error 10 in zpimZAgentPerf1Entry(): $@" );
		return $returnValue;
	}

}

################# - EOF - Zabbix Proxy Internal Monitoring - Common API Library

