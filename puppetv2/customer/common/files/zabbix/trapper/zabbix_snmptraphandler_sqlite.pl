#!/usr/bin/perl

use strict;
use DBI;

my $DEBUG = 1;
#my $DEBUGFILE = "/srv/zabbix/log/zabbix_snmptrapdebug_new.log";
my $DEBUGFILE = "/var/log/zabbix/zabbix_snmptrapdebug_sqlite.log";

my $ZABBIX_SERVER = "localhost";                     # Hostname/IP-Address of zabbix-server
#my $ZABBIX_SERVER = "hmspglobzmon";                     # Hostname/IP-Address of zabbix-server

my $ZABBIX_PORT = 10051;                                # Port of zabbix-server (Default: 10051)

my $ZABBIX_ITEM = "snmptraps";                          # Default item name to send traps to

#OLD Phil and Dimy package 
#my $ZABBIX_SENDER = "/srv/zabbix/bin/zabbix_sender";    # Path to your zabbix-sender
#New rpm package location 
my $ZABBIX_SENDER = "/usr/bin/zabbix_sender";
my $WILDCARD_HOST =  "TRAP_HOST";                       # Hostname or IP-Adress of wildcard-host within zabbix
my $SEND_ALL_TO_WILDCARD = 0;                       # Send all traps to wildcard host

# NEVER EVER CONTACT TO MAIN DB !!!!!!!! If a box starts to generate a TRAP storm, we are likely to kill the box
#my $ZABBIX_DB_HOST="hmspglobzdb";

# Requires zabbix-proxy to be on box and proxy be allocated to the machine as its trap handler
# Connect to local sqlite3 db
my $ZABBIX_DB_HOST="localhost";
# In sqlite DB_NAME is actually the name and full path to the zabbix-proxy db, in this case /tmp
my $ZABBIX_DB_NAME="/tmp/zabbix_proxy.db";
# Not used, hang on from original MySQL code
#my $ZABBIX_DB_NAME="zabbix";
#my $ZABBIX_DB_USER="zabbix";
#my $ZABBIX_DB_PASS="zabbix";

#Name of the file containing regular expresions if matched with whole combined SNMP trap string to not send them to Zabbix
my $TRAPEXCLUDEFILE="/srv/zabbix/etc/traps_to_exclude";

#Name of the file containing the ip<TAB>hostname. Just in case we receive different ip for the same hostname (multiple NICs)
my $ALIASFILE="/srv/zabbix/etc/aliasfile"; 

my $TRIMLONGVALUES=1;
#Do not edit below this line

my $KEYOIDNAME="SNMPv2-MIB::snmpTrapOID.0";

my $hostid;
my $item;
my $hostname_correct=0;

my $hostname = <STDIN>; #first line received from snmptrap is a hostname if applicable
loging('<hSTDIN> '.$hostname) if $DEBUG;
chomp($hostname);	

my $ipaddr = <STDIN>; #second line received from snmptrap is an IP address of trap sender in square brackets
loging('<iSTDIN> '.$ipaddr) if $DEBUG;
chomp($ipaddr);

$ipaddr =~ /.+\[(.+)\].+/;
#$ipaddr =~ /.*([\.|\w|\d]+)[ |\(].+[ |\)].+/;
my $ipaddress = $1;

my $keyoidvalue; #OID value which will be used as a key item. Actually it is a OID of the trap
my $keyoidvaluenum; #OID numeric value which will be used as a key item. Actually it is a OID of the trap. We need it to find the proper item in the DB
my $str; #SNMP TRAP provided by snmptrap is consisting with several OID VALUE on each line. so for zabbix traps we are combining them in one line

while (my $line=<STDIN>) {
  loging('<STDIN> '.$line) if $DEBUG;
  #next we are removing snmp lines with unneccessary information, like community or trap (zabbix server) address. 
  #comment it if you are still need this info
  next if ($line=~/sysUpTimeInstance/i || $line=~/snmpTrapCommunity/i || $line=~/snmpTrapAddress/i);
  $line =~ s/"/\\"/gi;
  $line =~ /([^\s]+)\s+(.*)/;
  my $oid=$1;
  my $value=$2;
  loging("phil - oid : $oid, value : $value, KEYOIDNAME : $KEYOIDNAME") if $DEBUG;
  #($keyoidvalue)=split (/::/,$value) if ($oid=~/$KEYOIDNAME/);
  if ($oid=~/$KEYOIDNAME/) {
  	  $keyoidvalue=$value;
  	  $keyoidvaluenum=`snmptranslate -On $keyoidvalue 2>/dev/null`;
  	  $str=$str."$value";
  } else {
	if ($TRIMLONGVALUES) {
	  if ($oid =~ /::/) {
            my ($tmp,$oid1)=split (/::/,$oid);
            $oid=$oid1;
          }
	}
  	$str=$str.", $oid: $value";
  }
}
exit if excluded($str);#stop further processing as this TRAP's regexp is matched in the excluded file.

if (! $SEND_ALL_TO_WILDCARD) {
  #try to read the hostname from the alias file if exists.
  open (ALIAS, "<$ALIASFILE");
  while (my $aline=<ALIAS>) {
    if ($aline=~/^$ipaddress\t(.*)$/) {
      $hostname=$1;
      $hostname_correct=1;
      $SEND_ALL_TO_WILDCARD=0;
      last;
    }
  }
  close (ALIAS);
}

if (! $SEND_ALL_TO_WILDCARD) {

  my $dbh;
  my $selecth;
  my $error;
  #try to check if zabbix knows about this IP
  eval {
#MySQL connect
#  $dbh = DBI->connect("DBI:SQLite:database=$ZABBIX_DB_NAME;host=$ZABBIX_DB_HOST",
#                          $ZABBIX_DB_USER,
#                          $ZABBIX_DB_PASS,
#                          {'RaiseError' => 1}
#                      );
#sqlite connect
 $dbh = DBI->connect("DBI:SQLite:$ZABBIX_DB_NAME",
                          {'RaiseError' => 1}
                      );
  };
  $error=$@;




  if (defined $dbh) {
	      loging ("SELECT hostid,host,ip FROM hosts where ip='$ipaddress';") if $DEBUG;
    if (!$hostname_correct) {#as hostname is defined from alias file no need to check with IP first
      eval {
        $selecth = $dbh->selectrow_hashref("SELECT hostid,host,ip FROM hosts where ip='$ipaddress';");
      };
      $error=$@;    
    }
    if (!$error) {
      if (!defined $selecth->{'host'}) {
        #Zabbix do not knows the HOSTNAME. try now with hostname
        eval {
	      loging ("SELECT hostid,host,ip FROM hosts where host='$hostname';") if $DEBUG;
          $selecth = $dbh->selectrow_hashref("SELECT hostid,host,ip FROM hosts where host='$hostname';");
        };
        $error=$@;
        if (!$error) {
          if (!defined $selecth->{'host'}) { #ZABBIX do not knows about this HOST or IP. Send TRAP to WILDCARD_HOST
            $SEND_ALL_TO_WILDCARD=1;
          } else {#We found in a DB a hostname from hostname, now override $ip received from TRAP
              $ipaddress=$selecth->{'ip'};
              $hostid=$selecth->{'hostid'};              
          }
        } else {#Can not get data from MySQL. Send all TRAPS to WILDCARD_HOST
          $SEND_ALL_TO_WILDCARD=1;   
          loging ("Error working with DB - $error") if $DEBUG;
        }
      } else {#We found in a DB a hostname from IP, now override $hostname received from TRAP
          $hostname=$selecth->{'host'};
          $hostid=$selecth->{'hostid'};        	  
      }
    } else {#Can not get data from MySQL. Send all TRAPS to WILDCARD_HOST
      $SEND_ALL_TO_WILDCARD=1; 
      loging ("Error working with DB - $error") if $DEBUG;
    }
  loging ("Phil hostid : $hostid") if $DEBUG;
    if (defined $hostid) {#We know the hostid, so now it is time to get the Item if it exists.
      eval {
   		#Below select gives possibility to use more generic TRAP oid as a item key to catch several TRAP oids.
   		#For example, we can use as a key for an item a oid '.1.3.6.1' which will catch more detailed oid like '.1.3.6.1.4.1'
          loging ("Phil SELECT itemid,description,key_ FROM items where hostid='$hostid' and '$keyoidvaluenum' like concat(key_,'%') order by length(key_) desc limit 1;") if $DEBUG;
  		$selecth = $dbh->selectrow_hashref("SELECT itemid,description,key_ FROM items where hostid='$hostid' and '$keyoidvaluenum' like concat(key_,'%') order by length(key_) desc limit 1;");
      };
      $error=$@;
      if (!$error) {
          if (!defined $selecth->{'key_'}) { #ZABBIX do not knows about this key on this host. Send TRAP to default Item
            $item=$ZABBIX_ITEM;
          } else {
              $item=$selecth->{'key_'};
          }
      } else {#Can not get data from MySQL. Send all TRAPS to default Item
    		$item=$ZABBIX_ITEM;
    	}
    }
  } 

# exception, unable to connect to DB
else {#Can not connect to MySQL. Send all TAPS to WILDCARD_HOST
    $SEND_ALL_TO_WILDCARD=1;  
    loging ("Error connecting to DB: $error") if $DEBUG;
  }
}

if ($SEND_ALL_TO_WILDCARD) {
  $str = "($hostname, $ipaddress) ".$str;
  $hostname=$WILDCARD_HOST;
  $item=$ZABBIX_ITEM;
}


#MONEY SHOT RIGHT HERE !!!!!
my $mycommand = "$ZABBIX_SENDER -vv --zabbix-server $ZABBIX_SERVER --port $ZABBIX_PORT --host $hostname --key $item --value \"$str\"";

loging ($mycommand) if $DEBUG;
my $return = `$mycommand`;
loging ($return) if $DEBUG;
$return =~ /.*failed ([0-9]*).*/gi;
if ($1 > 0) {
  loging("Error sending command. Output is: $return") if $DEBUG;
}



########################
#
# Define sub-routines 
#
########################

sub excluded {
  my $cmd=shift;
  open (EXCL,"<$TRAPEXCLUDEFILE");
  while (my $line=<EXCL>) {
    chomp $line;
    if ($cmd=~/$line/) {
        loging("Excluded - ".$cmd) if $DEBUG;
	return 1;
    }
  }
  return 0;
}

sub loging {
  my $text=shift;
  chomp $text;
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
  my $datetimestamp=($year+1900)."-".(($mon+1)<10?"0".($mon+1):$mon+1)."-".(($mday<10)?"0".$mday:$mday)." ".(($hour<10)?"0".$hour:$hour).":".(($min<10)?"0".$min:$min).":".(($sec<10)?"0".$sec:$sec);

  open (ERROR, ">>$DEBUGFILE") or die "Cannot open $DEBUGFILE\n";
  print ERROR "$datetimestamp -- $$ --$text\n";
  close (ERROR);
}
