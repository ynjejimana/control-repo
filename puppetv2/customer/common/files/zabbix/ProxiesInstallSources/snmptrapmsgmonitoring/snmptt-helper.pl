#!/usr/bin/perl
#### Monitoring SNMP Trap Messages (SNMPTT Helper)
#### Version 2.51
#### Written by: Premysl Botek (premysl.botek@lab.com)
##################################################################################
#### Execution Requirements:
#### * All non-default Perl modules installed from section "use" below (i.e $ yum install perl-Time-HiRes, $ cpan Config::Std etc.)
##################################################################################
#
#
#
#
# Useful Links:
#
# http://docstore.mik.ua/orelly/networking_2ndEd/snmp/ch10_03.htm
#
# https://www.mkssoftware.com/docs/man1/snmptrapd.1.asp  : snmptrapd-passed parameters containing trap info
#
#
# valid tests
#
#
# V1:
#
# snmptrap  -v 1 -m ALL -c public 172.18.40.134 .1.3.6.1.6.3 localhost 6 1 20071105
#
#
#
# V2 + a variable binding:
#
# snmptrap -v 2c -c public 172.18.40.134 "" "NET-SNMP-MIB::netSnmpExperimental" NET-SNMP-MIB::netSnmpExperimental s "testbyPremek_8"
#
# -v 2c					# snmp trap version
# -c public				# snmp community
# 172.18.40.134			# target IP
# ""					# agent uptime, if left empty brackets, will be replaced by current agent uptime
#
#
#
# V2 + 3 variable bindings:
#
# $ /opt/OV/bin/snmptrap -c public nms \
# .1.3.6.1.4.1.2789.2500 "" 6 3003 "" \
# .1.3.6.1.4.1.2789.2500.3003.1 octetstringascii "Oracle" \
# .1.3.6.1.4.1.2789.2500.3003.2 octetstringascii "Backup Not Running" \
# .1.3.6.1.4.1.2789.2500.3003.3 octetstringascii "Call the DBA Now for Help"
#
#
# Multiple Int and String variable bindings: snmptrap -v 2c -c public 172.21.40.18 "" .1.3.6.1.4.1.674.10892.5.3.2.1.0.2233 netSnmpExampleInteger i 111 netSnmpExampleInteger i 222 NET-SNMP-MIB::netSnmpExperimental s "test"
# HMSP Alert: snmptrap -v 2c -c public 172.28.99.55 "" .1.3.6.1.4.1.2854.0.1 NET-SNMP-MIB::netSnmpExperimental s "premektest1"
#
# from Windows:
#
# nttrapgen.exe -d nms:162 -c public -o ^
# 1.3.6.1.4.1.2789.4025 -i 10.123.456.4 -g 6 -s 4025 -t 124501 ^
# -v 1.3.6.1.4.1.2789.4025.1 STRING 5 Minutes Left On UPS Battery
#
#
#
#
# VALID EXEC COMMAND LINE PARAMETERS IN MIB CONVERTED FILE (for known trap received):
# EXEC /srv/zabbix/scripts/snmptrapmsgmonitoring/snmptt-helper.pl $aR $A $o $s $N "Host Adapter Discovered: The HostAdapter# $1 with HostAdapter Id $2 and Manager Id $3 is discovered"
# Parameters: IP address, hostname if not same as IP, oid, severity, event name, additional info (= translated formatting line)
# note: known trap info arrives normally in a number of command line parameters
#
# VALID unknown_trap_exec_format PARAMETERS IN snmptt.ini (for unknown trap received):
# unknown_trap_exec_format = unrecognized_by_snmptt $aR $A $o $*
# Parameters: string "unknown_trap_exec_format", IP address, hostname if not same as IP, oid, expanded all other info
# note: unknown trap info arrives cummulated in the first command line parameter

## compiler declarations, environment setup

use v5.10;
use strict;

use Data::Dumper;
use DBI;
use Time::Piece;
use Switch;
use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);
use Data::UUID;
use Sys::Hostname;

# DEPENDENT SETTINGS (values need to be reverified/set correctly during each installation - for this script to work and be integrated with the rest of functionality)

our $scriptsBaseDir       = "/srv/zabbix/scripts/snmptrapmsgmonitoring";
our $logFileName          = "$scriptsBaseDir/log.txt";
our $coreDatabaseFileName = "$scriptsBaseDir/snmptrapmsgmonitoringdata.db";

our $systemTempDir               = "/tmp";
our $zabbixProxyDatabaseFileName = "$systemTempDir/zabbix_proxy.db";

my $zabbix_server = "localhost"
  ;  # local proxy that this script will submit trap messages to via zabbix_send
my $zabbix_port = 10051;

# zabbix_sender binary location
my $zabbix_sender = "zabbix_sender";

my $loggingLevel = 1
  ; # 0 - no logging, 1 - log errors only, 2 - log everything (errors, warnings, debug info)
my $logOutput = 2
  ; # 1 - output to console, 2 - output to log file, 3 - output to both console and log file

## End - DEPENDENT SETTINGS

my $webAppURL;
my $webAppScriptFileName = "snmptrappergui.php";

my $thisModuleID =
  "SNMPTT-HELPER";    # just for log file record identification purposes

my $unidentifiedDestinationsProxyTrapperQueueName =
  "UnidentifiedSNMPTrapHostsQueue"
  ; # name of the trapper item key on the Trapper proxy that will receive traps for all unresolved Zabbix hosts
my $zabbixResolvedHostTrapperDefaultQueueName =
  "SNMPTrapsDefaultQueue"
  ;    # name of the default queue trapper item key on the Zabbix host

my $zabbixResolvedHostTrapperElevatedQueueName =
  "SNMPTrapsElevatedQueue"
  ;    # name of the elevated queue trapper item key on the Zabbix host

my @unknownTrapArgs;

my $localDatabaseDBH;
my $dbhZabbixProxyDatabase;

my $thisProxyZabbixVersionMajor;    # 1 or 2 - supported Zabbix versions

my $recognizedBySNMPTT   = 0;
my $recognizedZabbixHost = 0;
my $forwardingRouteFound = 0;

my $trapSourceIP;
my $trapSeverity;
my $trapEventName;
my $trapHostName;
my $trapEventAddInfo;
my $trapSourceMsgOID;
my $trapGUID = GenerateGUID();
my $trapForwardResolvedZabbixHostname;
my $zabbixFormattedTrapMessage;

#my $proxyGeneratedInfoMessage = "";

my $programEntryTimeStamp;
my $trapProxyMessageId = 0;

my $sendTriggerClearingTrapMessages = 1
  ; # 1: - forward snmp trap messages to Zabbix in format blank+payload+blank - to ensure Zabbix trigger will fire and then go off

my $finalForwardZabbixHostname;
my $finalForwardZabbixHostQueueName;

my $lastSendTrapToZabbixOperationResultCode;
my $lastSendTrapToZabbixOperationErrorMessage;

my $thisProxyZabbixHostName;
my $additionalInfoURL;

# self reflection

# get system hostname and clean out possible domain (clean everything after first dot, inclusive)
#my @parts = split( '\.', hostname );
#my $thisMachineHostname = @parts[0];
my $thisMachineHostname = hostname;

## program entry point
## program initialization

my ( $s, $usec ) = gettimeofday();    # get microseconds haha
my $programEntryTimeStamp = localtime->strftime("%Y-%m-%d %H:%M:%S.") . ($usec);

logEvent( 1, "cmdline args1: " . Dumper(@ARGV) );

#my $commandline = join " ", $0, @ARGV;
#	logEvent( 1, "Used command line2: $commandline" );

@unknownTrapArgs = split( ' ', $ARGV[0] );
chomp(@unknownTrapArgs);

if ( @unknownTrapArgs[0] eq "unrecognized_by_snmptt" ) {

	$recognizedBySNMPTT = 0;
	$trapSourceIP       = @unknownTrapArgs[1];
	$trapHostName       = @unknownTrapArgs[2];
	$trapSourceMsgOID   = @unknownTrapArgs[3];

	for ( my $i = 4 ; $i < scalar(@unknownTrapArgs) ; $i++ ) {
		$trapEventAddInfo .= @unknownTrapArgs[$i] . " | ";
	}

	chop $trapEventAddInfo;
	chop $trapEventAddInfo;
	chop $trapEventAddInfo;

}
else {

	$recognizedBySNMPTT = 1;
	$trapSourceIP       = @ARGV[0];
	$trapHostName       = @ARGV[1];
	$trapSourceMsgOID   = @ARGV[2];
	$trapSeverity       = @ARGV[3];
	$trapEventName      = @ARGV[4];

	for ( my $i = 5 ; $i < scalar(@ARGV) ; $i++ ) {
		$trapEventAddInfo .= @ARGV[$i] . " | ";
	}

	chop $trapEventAddInfo;
	chop $trapEventAddInfo;
	chop $trapEventAddInfo;

}

## main execution block

# connect to core database

if ( !-f $coreDatabaseFileName ) {
	logEvent( 2, "Database file $coreDatabaseFileName does not exist" );
	exit 1;
}

$localDatabaseDBH = DBI->connect(
	"dbi:SQLite:dbname=$coreDatabaseFileName",
	"", "", { RaiseError => 1 },
  )

  || { logEvent( 2, "Can't connect to database: $DBI::errstr" )
	  && exit 1 };

# connect to zabbix proxy database

if ( !-f $zabbixProxyDatabaseFileName ) {
	logEvent( 2, "Database file $zabbixProxyDatabaseFileName does not exist" );
	exit 1;
}

$dbhZabbixProxyDatabase = DBI->connect(
	"dbi:SQLite:dbname=$zabbixProxyDatabaseFileName",
	"", "", { RaiseError => 1 },
  )

  || { logEvent( 2, "Can't connect to database: $DBI::errstr" )
	  && exit 1 };

##

$webAppURL = readSettingFromDatabase1("WEB_APP_URL");

if ( !defined($webAppURL) ) {
	logEvent( 2, "WEB_APP_URL does not exist in TA_SETTINGS. Terminating." );
	exit 1;
}

$thisProxyZabbixHostName = $thisMachineHostname;

#if ( $thisProxyZabbixHostName eq "" ) {
#	logEvent( 2,
#		"THIS_PROXY_ZABBIX_HOSTNAME in TA_SETTINGS is empty. Terminating." );
#	exit 1;
#}

logEvent( 1, "thisProxyZabbixHostName: $thisProxyZabbixHostName" );

$thisProxyZabbixVersionMajor = readSettingFromDatabase1("ZABBIX_VERSION_MAJOR");

if ( !defined($thisProxyZabbixVersionMajor) ) {
	logEvent( 2,
"$thisProxyZabbixVersionMajor does not exist in TA_SETTINGS. Terminating."
	);
	exit 1;
}

##

# maintain TA_RECEIVED_TRAP_MSGS table (delete outdated records)
maintainHistoryDataRetention() or exit 1;

##

# decide where the trap will be forwarded to

$trapForwardResolvedZabbixHostname = ResolveZabbixHostFromIP($trapSourceIP);
logEvent( 1, "Resolved Zabbix hostname: $trapForwardResolvedZabbixHostname" );

if ( $trapForwardResolvedZabbixHostname ne "" ) {
	$trapHostName = $trapForwardResolvedZabbixHostname;

}

# format the Zabbix trap message

$additionalInfoURL =
"http://$thisProxyZabbixHostName/snmptrapmsgmonitoring/$webAppScriptFileName?a=9&msgguid=$trapGUID"
  . " (you may have to use the local environment terminal to access this link)";

if ( $recognizedBySNMPTT == 1 ) {

	my $tmpStr1 = $trapHostName;
	if ( $trapHostName ne $trapSourceIP ) {
		$tmpStr1 .= " ($trapSourceIP)";
	}

	$zabbixFormattedTrapMessage = "Source Host: " . $tmpStr1 . "\n";

	#	$zabbixFormattedTrapMessage .= "Trap OID: " . $trapSourceMsgOID . "\n";
	$zabbixFormattedTrapMessage .= "Event Severity: " . $trapSeverity . "\n";
	$zabbixFormattedTrapMessage .= "Event Name: " . $trapEventName . "\n";
	$zabbixFormattedTrapMessage .= "Event Details: " . $trapEventAddInfo . "\n";
	$zabbixFormattedTrapMessage .= "Additional Info: " . $additionalInfoURL;

}
else {

	my $tmpStr1 = $trapHostName;
	if ( $trapHostName ne $trapSourceIP ) {
		$tmpStr1 .= " ($trapSourceIP)";
	}

	$zabbixFormattedTrapMessage = "Source Host: " . $tmpStr1 . "\n";
	$zabbixFormattedTrapMessage .= "Trap OID: " . $trapSourceMsgOID . "\n";
	$zabbixFormattedTrapMessage .=
	  "Captured Parameters: " . $trapEventAddInfo . "\n";
	$zabbixFormattedTrapMessage .= "Additional Info: " . $additionalInfoURL;

}

$finalForwardZabbixHostname      = $trapForwardResolvedZabbixHostname;
$finalForwardZabbixHostQueueName = "";

if ( $trapForwardResolvedZabbixHostname eq "" )
{ # unidentified trap destination - forwarded to the proxy (proxy name stripped off the domain name like all hosts in Zabbix are)

	#$finalForwardZabbixHostname = $thisProxyZabbixHostName;

	my @parts = split( '\.', $thisProxyZabbixHostName );
	$finalForwardZabbixHostname = @parts[0];

}
else {

	$recognizedZabbixHost = 1;

}

if ( IsHostInMaintenanceMode($trapSourceIP) == 1 ) {

	$lastSendTrapToZabbixOperationResultCode = -2;
	$lastSendTrapToZabbixOperationErrorMessage =
	  "Host currently in maintenance mode - not forwarded to Zabbix";
	logEvent( 1, $lastSendTrapToZabbixOperationErrorMessage );

}
else {

	$finalForwardZabbixHostQueueName = GetDestinationZabbixQueueForMessage();

	if ( $finalForwardZabbixHostQueueName ne "" ) {

		$forwardingRouteFound = 1;

	}

	else {

		$lastSendTrapToZabbixOperationResultCode = -1;
		$lastSendTrapToZabbixOperationErrorMessage =
		  "No route found for this message - not forwarded to Zabbix";
		logEvent( 2, $lastSendTrapToZabbixOperationErrorMessage );

	}

}

# save trap message info to database - step 1 (create new record and get back ID)

eval {

	logEvent( 1, "Saving trap to database1" );

	$trapProxyMessageId = writeSNMPTrapMsgToDatabase1(
		$recognizedZabbixHost, $recognizedBySNMPTT,
		$trapForwardResolvedZabbixHostname, $trapSourceIP, $trapSeverity,
		$trapEventName,
		$trapEventAddInfo, $trapSourceMsgOID, $trapHostName, $trapGUID

	) || exit 1;

};
if ($@) {

	logEvent( 2, "Error 1 occured in collectGeneralHostStats(): $@" );

	exit 1;

}

# build proxy generated message string

#$proxyGeneratedInfoMessage = FormatProxyGeneratedMessage1();

if ( $forwardingRouteFound == 1 ) {

	if ( $sendTriggerClearingTrapMessages ==
		0 )    # forward message payload to zabbix - without any padding
	{

		SendTrapToZabbix( $finalForwardZabbixHostname,
			$finalForwardZabbixHostQueueName,
			$zabbixFormattedTrapMessage );

	}
	else
	{ # send the whole sequence blank+payload+blank - to ensure Zabbix trigger will fire and then go off

		SendTrapToZabbix(    # send blank trap message
			$finalForwardZabbixHostname,
			$finalForwardZabbixHostQueueName,
			""
		);

		if ( $lastSendTrapToZabbixOperationResultCode == 1 ) {

			sleep(1);

			SendTrapToZabbix(    # send trap message payload
				$finalForwardZabbixHostname,
				$finalForwardZabbixHostQueueName,
				$zabbixFormattedTrapMessage
			);

			if ( $lastSendTrapToZabbixOperationResultCode == 0 ) {

				$lastSendTrapToZabbixOperationResultCode = 100;
			}

		}

		#	send trigger clearing trap message
		if ( $lastSendTrapToZabbixOperationResultCode == 1 ) {

			sleep(1);

			SendTrapToZabbix(
				$finalForwardZabbixHostname,    # send trap message payload
				$finalForwardZabbixHostQueueName, ""
			);

			if ( $lastSendTrapToZabbixOperationResultCode == 0 ) {

				$lastSendTrapToZabbixOperationResultCode = 200;
			}

		}

	}

}

# save trap message info to database - step 2 (update existing record with new info)

eval {

	logEvent( 1, "Saving trap to database2" );

	$trapProxyMessageId = writeSNMPTrapMsgToDatabase2(
		$trapProxyMessageId,
		$finalForwardZabbixHostname,
		$finalForwardZabbixHostQueueName,
		$lastSendTrapToZabbixOperationResultCode,
		$lastSendTrapToZabbixOperationErrorMessage
	) || exit 1;

};
if ($@) {

	logEvent( 2, "Error 2 occured in collectGeneralHostStats(): $@" );

	exit 1;

}

# safe way to close sqlite database
undef $dbhZabbixProxyDatabase;
undef $localDatabaseDBH;

## end - main execution block

##  program exit point	###########################################################################

## service functions


sub GenerateGUID {
  my $ug    = Data::UUID->new;
  my $uuid = $ug->create();
  my $uniqueIdString  = $ug->to_string( $uuid );
  $uniqueIdString =~ s/-//g;
  return $uniqueIdString;
}


#sub GenerateGUID {
#	my $guid           = Data::GUID->new;
#	my $uniqueIdString = lc( Data::GUID->new->as_string );
#	$uniqueIdString =~ s/-//g;
#	return $uniqueIdString;
#}

#sub FormatProxyGeneratedMessage1 {
#
#	return
#"MsgPId: $trapProxyMessageId; Time Received: $programEntryTimeStamp; Source DNS name: $val2; Identified Zabbix Hostname: $trapForwardResolvedZabbixHostname; Extended Info: "
#	  . $webAppURL
#	  . $webAppScriptFileName
#	  . "?a=9&msgpid="
#	  . $trapProxyMessageId;
#
#}

#sub FormatTrapMessage1 {
#
#	return
#"  OID: $val1  \|  Source IP: $val3  \|  Source Uptime: $val4  \|  Data1: $val5  \|  Data2: $val6  \|  Variable Binding 1: $val7";
#
#
#}

sub GetDestinationZabbixQueueForMessage
{    # message routing logic implemented here
	my $result = "";
	my $sql1;
	my $sth;
	my $isHostListed;

	$isHostListed = IsHostListedInCoreDatabase($finalForwardZabbixHostname);

## find a Default Route for the current host

	eval {

		if ( $isHostListed == 1 )
		{ # host is listed -> try to find default rule for it (specific host, all OIDs)

# nested query: will return the very first message forwarding record for the selected host - first records
# is always Default Queue record
			$sql1 = <<DELIMITER1;
		
SELECT B.DS_QUEUE_NAME
FROM TA_FORWARD_RULES_MESSAGES A,TA_FORWARD_RULES_QUEUES B, TA_FORWARD_RULES_HOSTS C
WHERE A.DL_QUEUE_ID=B.DL_ID AND A.DL_HOST_ID=C.DL_ID 
AND C.DS_HOST_NAME=?
ORDER BY A.DL_ID
		
DELIMITER1

			logEvent( 1, "Routing sql1 (listed host): $sql1" );

			$sth = $localDatabaseDBH->prepare($sql1);

			$sth->execute($finalForwardZabbixHostname);

		}
		else
		{ # host isn't listed -> get default rule for the proxy (very first record in table TA_FORWARD_RULES_MESSAGES) (all hosts, all OIDs)

			$sql1 = <<DELIMITER1;
		
SELECT B.DS_QUEUE_NAME
FROM TA_FORWARD_RULES_MESSAGES A,TA_FORWARD_RULES_QUEUES B, TA_FORWARD_RULES_HOSTS C
WHERE A.DL_QUEUE_ID=B.DL_ID AND A.DL_HOST_ID=C.DL_ID 
AND A.DL_ID=1
		
DELIMITER1

			logEvent( 1, "Routing sql1 (unlisted host): $sql1" );

			$sth = $localDatabaseDBH->prepare($sql1);

			$sth->execute();

		}

		( my $tmpResult1 ) = $sth->fetchrow_array();

		if ( defined($tmpResult1) ) {
			$result = $tmpResult1;
		}

		$sth->finish();   # end statement, release resources (not a transaction)
	};

	if ($@) {

		logEvent( 2,
			"Error 1 occured in GetDestinationZabbixQueueForMessage(): $@" );

	}

## overwrite Default Route with the explicit route for OID - if it exists  (specific host, specific OID)

	eval {

		if ( $isHostListed == 1 )
		{    # host is listed -> try to find explicit OID rule for it

			$sql1 = <<DELIMITER1;
		
SELECT B.DS_QUEUE_NAME
FROM TA_FORWARD_RULES_MESSAGES A,TA_FORWARD_RULES_QUEUES B, TA_FORWARD_RULES_HOSTS C
WHERE A.DL_QUEUE_ID=B.DL_ID AND A.DL_HOST_ID=C.DL_ID 
AND C.DS_HOST_NAME=? AND A.DS_MSG_OID=?	
		
DELIMITER1

			logEvent( 1, "Routing sql2 (listed host): $sql1" );

			$sth = $localDatabaseDBH->prepare($sql1);

			$sth->execute( $finalForwardZabbixHostname, $trapSourceMsgOID );

		}
		else
		{ # host isn't listed -> get explicit OID rule for the proxy (proxy, specific OID)

# nested query: will return the very first message forwarding record for the selected host - first records
# is always Default Queue record
			$sql1 = <<DELIMITER1;
		
SELECT B.DS_QUEUE_NAME
FROM TA_FORWARD_RULES_MESSAGES A,TA_FORWARD_RULES_QUEUES B, TA_FORWARD_RULES_HOSTS C
WHERE A.DL_QUEUE_ID=B.DL_ID AND A.DL_HOST_ID=C.DL_ID 
AND A.DS_MSG_OID=? AND C.DL_ID=1;	
		
DELIMITER1

			logEvent( 1, "Routing sql2 (unlisted host): $sql1" );

			$sth = $localDatabaseDBH->prepare($sql1);

			$sth->execute($trapSourceMsgOID);

		}

		( my $tmpResult1 ) = $sth->fetchrow_array();

		if ( defined($tmpResult1) ) {
			$result = $tmpResult1;
		}

		$sth->finish();   # end statement, release resources (not a transaction)
	};

	if ($@) {

		logEvent( 2,
			"Error 2 occured in GetDestinationZabbixQueueForMessage(): $@" );

	}

	logEvent( 1, "Message routing result: $result" );
	return $result;
}

## check if host is registered in core database
sub IsHostListedInCoreDatabase {
	my ($host) = @_;
	my $result = 0;

	eval {

		my $sql1 =
		  "SELECT 1 FROM TA_FORWARD_RULES_HOSTS WHERE DS_HOST_NAME=\"$host\"";

		my $sth = $localDatabaseDBH->prepare($sql1);

		$sth->execute();

		($result) = $sth->fetchrow_array();

		if ( defined($result) ) {
			$result = 1;
		}

		$sth->finish();   # end statement, release resources (not a transaction)

	};

	if ($@) {

		logEvent( 2, "Error 1 occured in IsHostListedInCoreDatabase(): $@" );

	}

	return $result;
}

## check if host is currently being maintained
sub IsHostInMaintenanceMode {
	my ($hostIP) = @_;
	my $returnValue = 0;

	eval {

		my $sql1 = <<DELIMITER1;
		
SELECT COUNT(1) FROM TA_MAINTENANCE A
WHERE A.DL_STATUS=1
AND A.DT_START<datetime('now','localtime')
AND A.DT_END>datetime('now','localtime')
AND DS_HOST_IP=?

DELIMITER1

		my $sth = $localDatabaseDBH->prepare($sql1);

		$sth->execute($hostIP);

		my (@queryResult) = $sth->fetchrow_array();

		if ( @queryResult[0] > 0 ) {
			$returnValue = 1;
		}

		$sth->finish();   # end statement, release resources (not a transaction)

	};

	if ($@) {

		logEvent( 2, "Error 1 occured in IsHostInMaintenanceMode(): $@" );

	}

	return $returnValue;
}

sub ResolveZabbixHostFromIP {
	my ($IP) = @_;
	my $result;
	my $sql1;

	eval {

		if ( $thisProxyZabbixVersionMajor == 1 ) {
			$sql1 = "SELECT host FROM hosts WHERE ip=\"$IP\"";
		}
		else {
			$sql1 =
"SELECT A.host FROM hosts A,interface B WHERE A.hostid=B.hostid AND B.ip=\"$IP\" AND B.main=1";
		}

		logEvent( 1, "ResolveZabbixHostFromIP(): sql1: $sql1" );

		my $sth = $dbhZabbixProxyDatabase->prepare($sql1);

		$sth->execute();

		($result) = $sth->fetchrow_array();

		if ( !defined($result) ) {
			$result = "";
		}

		$sth->finish();   # end statement, release resources (not a transaction)

		logEvent( 1, "ResolveZabbixHostFromIP(): resolved hostname: $result" );

	};

	if ($@) {

		logEvent( 2, "Error 1 occured in ResolveZabbixHostFromIP(): $@" );

	}

	return $result;
}

sub SendTrapToZabbix {
	my ( $zabbixHost, $key, $msg ) = @_;
	my $result = 0;
	my $returnBuff;

	# Start the final command string
	my $cmd =
	    $zabbix_sender
	  . " --zabbix-server "
	  . $zabbix_server
	  . " --port "
	  . $zabbix_port
	  . " --host "
	  . $zabbixHost
	  . " --key $key --value";
	$cmd = $cmd . " \"" . $msg . "\"";

	#$cmd = $cmd . " \"" . $val2 . " :: " . $val3 . " - " . $val4 . "\"";

	logEvent( 1, "cmd: $cmd" );

	$returnBuff = `$cmd`;

	chomp($returnBuff);

	logEvent( 1, "return info: $returnBuff" );

	$returnBuff =~ /.*Failed\s+([0-9])/;
	if ( $1 > 0 || !$returnBuff ) {

		$lastSendTrapToZabbixOperationErrorMessage =
		  "ERROR: Failed to send item using command: $cmd";
		logEvent( 2, $lastSendTrapToZabbixOperationErrorMessage );

	}
	else {
		logEvent( 1, "Sending using command $cmd was successful." );

		$result = 1;

	}

	$lastSendTrapToZabbixOperationResultCode = $result;
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

sub writeSNMPTrapMsgToDatabase1
{ # Saving step 1: returns 0 or ID of the inserted row (will need it for further updating)

	my (
		$recognizedZabbixHost, $recognizedBySNMPTT, $zabbixHostname,
		$lTrapSourceIp,        $lTrapSeverity,      $lTrapName,
		$lTrapAddInfo,         $lTrapSourceMsgOID,  $lResolvedDnsHost,
		$lTrapGUID
	) = @_;
	my $subresult = 0;
	my $sql1;

	eval {

		# write new row to database

		$localDatabaseDBH->begin_work();

		$sql1 =
"INSERT INTO TA_RECEIVED_TRAP_MSGS (DL_RECOGNIZED_ZABBIX_HOST,DL_RECOGNIZED_BY_SNMPTT,
DS_SOURCE_IP,DS_SEVERITY,DS_NAME,DS_ADD_INFO,DS_OID,DS_GUID,DS_SOURCE_HOST) VALUES 
(?,?,?,?,?,?,?,?,?)";

		my $sth = $localDatabaseDBH->prepare($sql1);

		$sth->execute(
			$recognizedZabbixHost, $recognizedBySNMPTT, $lTrapSourceIp,
			$lTrapSeverity,        $lTrapName,          $lTrapAddInfo,
			$lTrapSourceMsgOID,    $lTrapGUID,          $lResolvedDnsHost
		);

		$sth->finish();

		# retrieve most recent row's ID
		$sql1 = "SELECT MAX(DL_ID) FROM TA_RECEIVED_TRAP_MSGS";

		my $sth = $localDatabaseDBH->prepare($sql1);

		$sth->execute();

		( my $queryResult ) = $sth->fetchrow_array();

		if ( defined($queryResult) ) {
			$subresult = $queryResult;
		}

		$sth->finish();   # end statement, release resources (not a transaction)

		# finalize transaction

		$localDatabaseDBH->commit();

	};

	if ($@) {

		$subresult = 0;

		logEvent( 2, "Error 1 occured in writeSNMPTrapMsgToDatabase1(): $@" );

		eval { $localDatabaseDBH->rollback(); };

	}

	return $subresult;

}

sub writeSNMPTrapMsgToDatabase2
{    # Saving step 2: returns 0, or 1 if operation was successful

	my ( $recordID, $zabbixHost, $zabbixMessageQueue, $zabbixSendingResult,
		$zabbixSendingErrorMessage )
	  = @_;
	my $subresult = 0;
	my $sql1;

	eval {

		# write new row to database

		$localDatabaseDBH->begin_work();

		$sql1 =
"UPDATE TA_RECEIVED_TRAP_MSGS SET DS_ZABBIX_SENDER_FORWARDING_HOST=\"$zabbixHost\",DS_ZABBIX_SENDER_FORWARDING_QUEUE=\"$zabbixMessageQueue\",DL_ZABBIX_SENDER_FORWARDING_RESULT_CODE=$zabbixSendingResult, DS_ZABBIX_SENDER_FORWARDING_ERROR_DESCRIPTION=\"$zabbixSendingErrorMessage\" WHERE DL_ID=$recordID";

		$localDatabaseDBH->do($sql1);

		# finalize transaction

		$localDatabaseDBH->commit();

	};

	if ($@) {

		$subresult = 0;

		logEvent( 2, "Error 1 occured in writeSNMPTrapMsgToDatabase2(): $@" );
		eval { $localDatabaseDBH->rollback(); };

	}

	return $subresult;

}

sub maintainHistoryDataRetention {
	my $subresult = 0;
	my $dataRetentionPeriod;
	my $lastMaintenanceTimestamp;
	my $maintenanceInterval;
	my $rowsAffected;

	$lastMaintenanceTimestamp =
	  readSettingFromDatabase1(
		"LAST_DATA_RETENTION_LAST_MAINTENANCE_TIMESTAMP");

	if ( !defined($lastMaintenanceTimestamp) ) {
		logEvent( 2,
"LAST_DATA_RETENTION_LAST_MAINTENANCE_TIMESTAMP does not exist in TA_SETTINGS"
		);
		return $subresult;

	}

	$maintenanceInterval =
	  readSettingFromDatabase1("DATA_RETENTION_LAST_MAINTENANCE_INTERVAL");

	if ( !defined($maintenanceInterval) ) {
		logEvent( 2,
"DATA_RETENTION_LAST_MAINTENANCE_INTERVAL does not exist in TA_SETTINGS"
		);
		return $subresult;

	}

	$dataRetentionPeriod = readSettingFromDatabase1("DATA_RETENTION_PERIOD");

	if ( !defined($dataRetentionPeriod) ) {
		logEvent( 2, "DATA_RETENTION_PERIOD does not exist in TA_SETTINGS" );
		return $subresult;

	}

##

	if ( $dataRetentionPeriod == 0 ) {
		return 1;
	}

	my $nextMaintenanceTime = date(
		strtotime(
			    $lastMaintenanceTimestamp . ' + '
			  . $maintenanceInterval
			  . ' minute'
		)
	);

	if (   ( $nextMaintenanceTime > time() )
		|| ( $lastMaintenanceTimestamp eq "" ) )
	{
		return 1;

	}
##

	eval {

		my $sql1 =
"DELETE FROM TA_RECEIVED_TRAP_MSGS WHERE DATETIME(DT_TIMESTAMP)<DATETIME(DATETIME( 'now' , 'localtime' ),'-"
		  . $dataRetentionPeriod
		  . " day')";

		my $sth = $localDatabaseDBH->prepare($sql1);

		$rowsAffected =
		  $sth->execute()
		  ; # no need for manual transaction, we are just running one statement here

		$sth->finish();   # end statement, release resources (not a transaction)

		if ( $rowsAffected == 0 ) {    # just so we dont get 0E0
			$rowsAffected = 0;
		}

		logEvent( 1,
			"Maintaining Data Retention, $rowsAffected rows deleted." );

		if (
			writeSettingToDatabase1(
				"LAST_DATA_RETENTION_LAST_MAINTENANCE_TIMESTAMP", time()
			)
		  )
		{
			$subresult = 1;

		}

	};

	if ($@) {

		logEvent( 2, "Error 1 occured in maintainHistoryDataRetention(): $@" );

	}

	return $subresult;

}

sub writeSettingToDatabase1 {
	my ( $key1, $value1 ) = @_;
	my $subresult = 0;

	eval {

		my $sql1 =
		  "UPDATE TA_SETTINGS SET DS_VALUE=\"$value1\" WHERE DS_KEY=\"$key1\"";

		my $sth = $localDatabaseDBH->prepare($sql1);

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

		return
		  ; # returns only from this eval block, not from the sub. Very "smart" feature of Perl...

	};

	if ($@) {

		logEvent( 2, "Error 2 occured in writeSettingToDatabase1(): $@" );

	}

	return $subresult;

}

sub readSettingFromDatabase1 {
	my ($key1) =   # expects reference to variable $value1 (so it can modify it)
	  @_;
	my $subresult;

	eval {

		my $sql1 = "SELECT DS_VALUE FROM TA_SETTINGS WHERE DS_KEY=?";

		my $sth = $localDatabaseDBH->prepare($sql1);

		$sth->execute($key1);

		#$tmp1 = $sth->fetch();
		($subresult) = $sth->fetchrow_array();

		$sth->finish();   # end statement, release resources (not a transaction)

		if ( !defined($subresult) ) {

			logEvent( 2, "The setting value for the key $key1 does not exist" );

		}

	};

	if ($@) {

		logEvent( 2, "Error 1 occured in readSettingFromDatabase1(): $@" );

	}

	return $subresult;

}
