#!/usr/bin/perl
#### Utilities Monitoring V1 (Zabbix utility services monitoring utility)
#### Version 1.36
#### Written by: Premysl Botek (premysl.botek@lab.com)
##################################################################################
#### Execution Requirements:
#### * All non-default Perl modules listed as "use" from section "pragmas ..." below (i.e $ yum install perl-Time-HiRes perl-Net-SNMP, $ cpan Config::Std etc.)
##################################################################################
#
#
#

# NOTES: use Net::Nslookup installed manually, prerequisite Net::DNS from yum

## pragmas, global variable declarations, environment setup

use v5.10;
use strict;

#no if $] >= 5.018, 'warnings', "experimental::smartmatch";
use Data::Dumper;
use Time::Piece;
use Time::Seconds;
use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);
use DBI;
use Net::SMTP;
use Net::DNS::Dig;
use NetAddr::IP::Util qw(inet_ntoa);
use Net::OpenSSH;
use Net::NTP;
use IO::Pty;
no if $] >= 5.018, warnings => "experimental::smartmatch";

use Net::SSL::ExpireDate;
use Time::ParseDate;

# DEPENDENT SETTINGS (values need to be reverified/set correctly during each installation - for this script to work and be integrated with the rest of functionality)

our $scriptsBaseDir        = "/srv/zabbix/scripts/utilitiesmonitoring";
our $logFileName           = "$scriptsBaseDir/log.txt";
our $localDatabaseFileName = "$scriptsBaseDir/utilitiesmonitoringdata.db";

my $loggingLevel = 1
  ; # 0 - no logging, 1 - log errors only, 2 - log everything (errors, warnings, debug info)
my $logOutput = 2
  ; # 1 - output to console, 2 - output to log file, 3 - output to both console and log file

my $zpimZAgentPerf1TracingEnabled = 1;
my $zpimBaseDir                   = "/srv/zabbix/scripts/zpimonitoring";

my $remoteCommandConnectionTimeout = 30;

## End - DEPENDENT SETTINGS

my $thisModuleID =
  "GET-DATA";    # just for log file record identification purposes

my $zpimDatabase1FileName = "$zpimBaseDir/zpimonitoring.db";
my $zpimZAgentPerf1Tracing_SNMPMonitoringGetDataAnchor1_GUID =
  'b2b0de57-ce09-476c-b004-015306ddcce5';
my $zpimZAgentPerf1Tracing_SNMPMonitoringGetDataAnchor1_TimeStamp0;

my $returnCode;
my $returnValue;

my $appMode = 0;

my $ssh_pipe;

my $invalidCommandLine = 0;

my $scriptLogFileErrorsCount;

#my $currentZabbixHostReference;

my $globMachineName;
my $globMachineUsername = 'root';
my $globMachinePassword = 'xxxx';

my $check1_connectionTimeout = 10;    # [seconds]
my $check1_port;

my $check2_statName;

my $check3_domain;
my $check3_queryType;
my $check3_timeout = 5;
my $check3_port;

my $check4_port;

my $check5_remoteCmd_postqueue = "postqueue -p | grep -v empty | wc -l";
my $check5_remoteCmd_execResult_postqueue;
my @check5_remoteCmd_collectedDetails_postqueue;

my $check6_domain;

my $failedRemoteCommandsCount = 0;

## program entry point

main();

##  program exit point	###########################################################################

sub main {

	## program initialization

	my $commandline = join " ", $0, @ARGV;
	logEvent( 1, "Used command line: $commandline" );

	if ( scalar(@ARGV) < 1 ) {
		$invalidCommandLine = 1;
	}
	else {

		$invalidCommandLine = 1;

		given ( uc( $ARGV[0] ) ) {    # identify check group

			when ("1") {              # SMTP utilities group

				given ( uc( $ARGV[1] ) ) {    # identify command

					when ("1") {

						if ( scalar(@ARGV) >= 4 ) {

							$globMachineName = $ARGV[2];
							$check1_port     = $ARGV[3];

							$appMode = 1;     # get SMTP helo response banner
							$invalidCommandLine = 0;

						}

					}

				}

			}

			when ("2") {                      # postfix utilities group

				given ( uc( $ARGV[1] ) ) {    # identify command

					when ("1") {

						if ( scalar(@ARGV) >= 3 ) {

							$globMachineName = $ARGV[2];

							$appMode = 5;     # get postfix mail queue length
							$invalidCommandLine = 0;

						}

					}

				}

			}

			when ("3") {                      # DNS utilities group

				given ( uc( $ARGV[1] ) ) {    # identify command

					when ("1") {

						if ( scalar(@ARGV) >= 6 ) {

							$globMachineName  = $ARGV[2];
							$check3_domain    = $ARGV[3];
							$check3_queryType = $ARGV[4];
							$check3_port      = $ARGV[5];

							$appMode            = 3;    # get dig response
							$invalidCommandLine = 0;

						}

					}

				}

			}

			when ("4") {                                # NTP utilities group

				given ( uc( $ARGV[1] ) ) {              # identify command

					when ("1") {

						if ( scalar(@ARGV) >= 4 ) {

							$globMachineName = $ARGV[2];
							$check4_port     = $ARGV[3];

							$appMode            = 4;    # get NTP query response
							$invalidCommandLine = 0;

						}

					}

				}

			}

			when ("5") {    # proxy housekeeping group

				given ( uc( $ARGV[1] ) ) {    # identify command

					when ("1") {

						if ( scalar(@ARGV) >= 2 ) {

							$appMode = 6;     # get scripts log error count
							$invalidCommandLine = 0;

						}

					}

				}

			}

			when ("6") {                      # SSL utilities group

				given ( uc( $ARGV[1] ) ) {    # identify command

					when ("1") {

						if ( scalar(@ARGV) >= 3 ) {

							$check6_domain = $ARGV[2];

							$appMode = 7;     # get domain expiry remainer
							$invalidCommandLine = 0;

						}

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
	
USAGE:		perl snmpm-get-data.pl <cmdID> ...
	
* when cmdId is 1, remaining parameters are: <itemOIDprefix> <itemOIDIndex> <Host> <SNMPCommunity> <SNMPVersion> [zabbixHostNameReference] - Executes the specified SNMP query and returns its result. ZabbixHostNameReference is used only for debugging reasons - to identify in the log file where SNMP requests come from. 

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
		$zpimZAgentPerf1Tracing_SNMPMonitoringGetDataAnchor1_GUID,
		\$zpimZAgentPerf1Tracing_SNMPMonitoringGetDataAnchor1_TimeStamp0,
		$$,
		$commandline,
		undef
	);

	given ($appMode) {

		when (1) {

			($returnValue) =
			  fnCheck_GetSMTPHelloResponse( $globMachineName, $check1_port );

			print $returnValue;

		}

		when (2) {

			($returnValue) =
			  readCollectedInfoKeypairFromDatabase1( $globMachineName,
				$check2_statName );

			print $returnValue;

		}

		when (3) {

			($returnValue) = fnCheck_GetDigResponseAnswerCount(
				$globMachineName,  $check3_domain,
				$check3_queryType, $check3_port
			);

			print $returnValue;

		}

		when (4) {

			($returnValue) =
			  fnCheck_GetNTPQueryResponse( $globMachineName, $check4_port );

			print $returnValue;

		}

		when (5) {

			($returnValue) =
			  fnCheck_GetPostfixMailQueueLength($globMachineName);

			print $returnValue;

		}

		when (6) {

			($returnValue) = fnGetScriptLogFileErrorCount();

			print $returnValue;

		}

		when (7) {

			($returnValue) =
			  fnCheck_GetNetSSLCertificateExpiryRemainer($check6_domain);

			print $returnValue;

		}

	}

	# remove anchor record from the internal monitoring db
	zpimZAgentPerf1Entry(
		2,
		$zpimZAgentPerf1Tracing_SNMPMonitoringGetDataAnchor1_GUID,
		\$zpimZAgentPerf1Tracing_SNMPMonitoringGetDataAnchor1_TimeStamp0,
		$$,
		undef,
		$returnValue
	);

## end - main execution block

}

sub fnCheck_GetNTPQueryResponse {
	my ( $machine, $port ) = @_;
	my $returnValue = "unknown_error";
	my %NTPQueryReponse;

	$Net::NTP::TIMEOUT =
	  10;    # yes we can modify module "our" variables like that!

	eval {

		%NTPQueryReponse = get_ntp_response( $machine, $port );

		if (%NTPQueryReponse) {    # if array is defined

			#$returnValue = join( '; ', @nslookupReponse );
			#print Dumper( \%NTPQueryReponse );
			$returnValue = Dumper( \%NTPQueryReponse );
		}
		else {

			logEvent( 2,
"Error 1 occured in fnCheck_GetNTPQueryResponse(). Empty response received from $machine on port $port"
			);
			$returnValue = "empty_response";
			return $returnValue;
		}

	};
	if ($@) {

		logEvent( 2,
"Error 2 occured in fnCheck_GetNTPQueryResponse(), machine $machine, port $port : $@"
		);
		$returnValue = "error_occured";
		return $returnValue;

	}

	return $returnValue;

}

# if domain is not expired yet, returns number of days - positive number
# if expired, returns 0
# if error occured, returns -1
sub fnCheck_GetNetSSLCertificateExpiryRemainer {
	my ($domain) = @_;
	my $returnValue = -1;    # default value: error

	eval {

		local $SIG{__WARN__} = sub
		{ # create handler to suppress die/warning message generated by Net::SSL::ExpireDate when domain is invalid
			my $message = shift;

			#print "no!\n";
			## do nothing to ignore all together

			## ignore specific message
			# warn $message unless $message =~ /No such file or directory/;

			## or do something else
			# die $message ## make fatal
			# open my $fh, '>', 'file.log'; print $fh $message;
		};

		logEvent( 1,
			"Checking ssl certificate expiry remainer for domain " . $domain );

		my $ed = Net::SSL::ExpireDate->new( https => $domain );

		if ( defined $ed->expire_date ) {

			my $expire_date = $ed->expire_date;    # return DateTime instance
			my $expireDays =
			  int( ( parsedate($expire_date) - time ) / ( 60 * 60 * 24 ) );

			if ( $expireDays > 0 ) {
				$returnValue = $expireDays;

			}
			else {
				$returnValue = 0;

			}

		}
		else {
			logEvent( 2,
"Error 2 occured in fnCheck_GetNetSSLCertificateExpiryRemainer()"
			);

		}
	};

	if ($@) {

		logEvent( 2,
			"Error 1 occured in fnCheck_GetNetSSLCertificateExpiryRemainer(): "
			  . $@ );

	}

	return $returnValue;

}

sub fnCheck_GetDigResponseAnswerCount {
	my ( $machine, $protocol, $domain, $port ) = @_;
	my $returnValue = -3;		# 0+ : number of dig answer records, -1 : query error occured (detail in log), -2 exception throwed in eval block (detail in log), -3 unknown error
	my @digResponse;
	my $queryType = 'A';

	eval {

		my $config = {
			Timeout  => $check3_timeout,
			PeerAddr => $machine,
			PeerPort => $port,
			Proto    => $protocol
		};


#		@digResponse =
#		  Net::DNS::Dig->new($config)->for( $domain, $queryType )->rdata();

		my $dig = new Net::DNS::Dig();

                my $dobj =$dig->new($config)->for( $domain, $queryType );

                
                
                if ($dobj->{Errno} eq ""){
                
                
                @digResponse =$dobj->rdata();			# get count of answer fields
                $returnValue = scalar(@digResponse);

		} else {
		
		
		logEvent( 2,"Error 1 occured in fnCheck_GetDigResponse(),machine: $machine, domain: $domain : ".$dobj->{Errno} );
		
		$returnValue = -1;
		
		
		}


		

	};

	if ($@) {

		logEvent( 2,
"Error 2 occured in fnCheck_GetDigResponse(),machine: $machine, domain: $domain : "
			  . $@ );

		$returnValue = -2;
		return $returnValue;

	}

	return $returnValue;

}





sub fnCheck_GetNSLookupResponse {
	my ( $machine, $domain, $queryType ) = @_;
	my $returnValue;
	my @nslookupReponse;

	@nslookupReponse =
	  nslookup( domain => $domain, server => $machine, type => $queryType );

	if (@nslookupReponse) {    # if array is defined

		$returnValue = join( '; ', @nslookupReponse );
	}
	else {

		logEvent( 2,
"Error 1 occured in fnCheck_GetNSLookupResponse(). No response from $machine to query $domain, querytype $queryType"
		);

	}

	return $returnValue;

}

sub fnCheck_GetPostfixMailQueueLength {
	my ($machine) = @_;
	my $returnValue = "-1";

	logEvent( 1, "Querying Postfix machine $machine" );

	$ssh_pipe = Net::OpenSSH->new(
		$machine,
		master_opts => [
			-o => "StrictHostKeyChecking=no",
			-o => "ConnectTimeout $remoteCommandConnectionTimeout"
		],

		#		user => $globMachineUsername,

		#		password => $globMachinePassword
		#		,    # use this if you do not want passwordless authentication
		strict_mode => 0,

	);

	$ssh_pipe->error
	  && {
		logEvent( 2,
"Error 1 in fnCheck_GetPostfixMailQueueLength(): SSH connection to Postfix machine $machine failed: "
			  . $ssh_pipe->error )
		  && return $returnValue
	  };

	# run remote cmd
	if (
		(
			$check5_remoteCmd_execResult_postqueue,
			@check5_remoteCmd_collectedDetails_postqueue
		)
		= exec_remote_command(
			"$check5_remoteCmd_postqueue;"

		)
	  )
	{

		$returnValue = @check5_remoteCmd_collectedDetails_postqueue[0];

	}
	else {

		$check5_remoteCmd_execResult_postqueue = 1;
		$failedRemoteCommandsCount++;
	}

	return $returnValue;

}

sub fnCheck_GetSMTPHelloResponse {
	my ( $hostName, $port ) = @_;
	my $returnValue = "unknown_error";
	my $SMTPConnection;

	eval {

		$SMTPConnection = Net::SMTP->new(
			$hostName,
			Hello   => 'smtp service checker',
			Timeout => $check1_connectionTimeout,
			Port    => $port
		);

		#print "banner: " . $SMTPConnection->banner . "\n";

		if ( defined($SMTPConnection) ) {

			$returnValue = $SMTPConnection->banner;

			undef $SMTPConnection;

		}
		else {

			logEvent( 2,
"Error 1 occured in fnCheck_GetSMTPHelloResponse(). Could not connect to SMTP server $hostName: $@"
			);
			$returnValue = "error_occured";
			return $returnValue;

		}

	};

	if ($@) {

		logEvent( 2, "Error 2 occured in fnCheck_GetSMTPHelloResponse(). $@" );
		$returnValue = "error_occured";
		return $returnValue;

	}

	return $returnValue;

}

sub readCollectedInfoKeypairFromDatabase1 {
	my ( $machine, $keypairStorePathSuffix ) = @_;
	my $returnValue;
	my $dbh;
	my $cluster_seq_no;
	my $keypairStorePath1 = "payload:$machine:$keypairStorePathSuffix";

	eval {

		# connect to database

		if ( !-f $localDatabaseFileName ) {
			logEvent( 2,
"Error 1 occured in readCollectedInfoKeypairFromDatabase1(). Database $localDatabaseFileName can not be opened"
			);
			return $returnValue;
		}

		$dbh = DBI->connect(
			"dbi:SQLite:dbname=$localDatabaseFileName",
			"", "", { RaiseError => 1 },
		);

		$dbh->begin_work();

		my $sql1 = <<DELIMITER1;
 
SELECT 

(
SELECT MAX(DL_CLUSTER_SEQ_NUMBER) FROM TA_COLLECTED_DATA
WHERE DS_STATNAME='metadata:seqfooter:param1'
) AS LAST_COMPLETED_CLUSTER_SEQ_NUMBER

DELIMITER1

		$sql1 =~ s/param1/$machine/g
		  ; # parameters in complex parametrized sqlite queries do not work well. we do parameter replacement ourselves

		my $sth1 = $dbh->prepare($sql1);

		$sth1->execute()
		  ; # get cluster sequence number of the very last completed data gathering operation

		($cluster_seq_no) = $sth1->fetchrow_array();

		$sth1->finish();

		if ( !defined($cluster_seq_no) ) {
			$cluster_seq_no = 0;
		}

# query the very last cluster data gathering sequence - to avoid returning some stale data
		my $sql1 =
"SELECT DS_VALUE FROM TA_COLLECTED_DATA WHERE DS_STATNAME=? AND DL_CLUSTER_SEQ_NUMBER=?";

		my $sth = $dbh->prepare($sql1);

		$sth->execute( $keypairStorePath1, $cluster_seq_no );

		($returnValue) = $sth->fetchrow_array();

		$sth->finish();

		$dbh->disconnect();

	};

	if ($@) {

		logEvent( 2,
			"Error 2 occured in readCollectedInfoKeypairFromDatabase1(). $@" );
		return $returnValue;

	}

	return $returnValue;

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

sub exec_remote_command {
	my ($cmd) = @_;        # expects reference to $collectedDetails
	my $returnValue = 0;
	my @collectedDetails;

	logEvent( 1, "Executing Remote SSH command : $cmd" );

	my ( $sshReadBuffer, $errput ) = $ssh_pipe->capture2(
		{ timeout => $remoteCommandConnectionTimeout, stdin_discard => 1 },
		$cmd )
	  ; # doco says that capture function honours input separator settings (local $/ = "\n";) when in array context, but really it does not...

#	!Don't use statement " || { logEvent( 2, "Error 1 occured in exec_remote_command() : " . $ssh_pipe->error )
#		  && return 0 }; " in here or $errput will not be retrieved correctly...

	if ( $ssh_pipe->error ) {
		logEvent( 2,
"Error 1 occured in exec_remote_command(): CMD : $cmd\nSTDIN: $sshReadBuffer\nSTDERR: $errput\nNet::SSH error : "
			  . $ssh_pipe->error );

		return ( $returnValue, @collectedDetails );
	}

	@collectedDetails =
	  split( "\n", $sshReadBuffer );    # modifies referred array, wot a beauti

	logEvent( 1, "Remote command result: " . Dumper(@collectedDetails) );

	$returnValue = 1;

	return ( $returnValue, @collectedDetails );

}

sub fnGetScriptLogFileErrorCount {      # method Version: 2
	my $returnValue              = -1;
	my $scriptLogFileErrorsCount = 0;

	if ( !open( INPUT, $logFileName ) ) {

		logEvent( 2, "Error 1 occured in fnGetScriptLogFileErrorCount(): $!" );

	}
	else {

		while ( my $line = <INPUT> ) {

			if ( $line =~ / !ERROR! / ) {

				$scriptLogFileErrorsCount++;

			}
		}

		close(INPUT);

		$returnValue = $scriptLogFileErrorsCount;

	}

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
		retrurn $returnValue;
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

			$zpimSth1->execute( $anchorLapsedTime, $dsVal2,
				$functinalityGUID, $sessionId );
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

