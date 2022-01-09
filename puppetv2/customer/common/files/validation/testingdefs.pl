use strict;

our $logfile;
#Globals vars etc..

chop (our $basedir = `pwd`);
our $pingtest = "perl $basedir/pingtest.pl";
our $ldaptest = "perl $basedir/ldaptest.pl";
our $dnstest = "perl $basedir/dnstest.pl";
our $ntptest = "perl $basedir/ntptest.pl";
our $smtptest = "perl $basedir/smtptest.pl";


our $progname = "HarbourMSP Unix Build Validation Error Report (HUBVER)";
our $progversion = "0.8";

#host info
our $hostname;
our $domainname;
our $fqdn;

our $os;
our $kernel;
our $processor;
our $memtotal;
our $swap;
our $swapfile;
our $distro;
our @cpus;
our @ipaddresses;
our $defaultgw;
our $redhatdiriv = 1;

#hosts
our @requiredhosts;

#interfaces
our %checkints;

#pings
our @standardpings;

#DNS
our @dnsservers;
our @dnscheckaddress;

#SMTP
our @mailservers;
our $mailfrom;
our $rcptto;

#LDAP
our @ldapservers;
our $ldapsecret;
our $ldapdn;
our $ldaptestuid;
our $ldapuserbase;
our $ldapgroupbase;

our %ldapusers;
our @checkldapusers;
our %checkldapusers;

our %ldapgroups;
our @checkldapgroups;
our %checkldapgroups;

#Mounts
our @mounts;
our @checkmountsnfs;
our @checkmountslocal;

#ports
our @openports;
our @checkportprotocols;

#users
our %users;
our %checkusers;

#groups
our %groups;
our %checkgroups;

#perms
our %perms;

#NTP
our @ntpservers;

#packages
our %packages;
our @checkpkgs;

#kernel Parameters
our %kernelparams;
our @checkkernelparams;

our $timestamp;

our $hostfile;

sub test
{
        return 1;
}

1;
