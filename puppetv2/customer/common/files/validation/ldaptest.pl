#!/usr/bin/perl

use Getopt::Long;
use Net::LDAP;

our %optctl;

#Globals vars etc..

my $secret="";
#my $dn="cn=admin,dc=harbourmsp,dc=com";
my $dn="cn=root,dc=harbourmsp,dc=com";
my $server = "ldap.harbour";
#my $userbase="ou=people,dc=oraclecrm,dc=com";
my $userbase="ou=People,dc=harbourmsp,dc=com";
#my $groupbase="ou=groups,dc=oraclecrm,dc=com";
my $groupbase="ou=groups,dc=harbourmsp,dc=com";
my $uid;
my $cn;

my $dousersearch = 0;
my $dogroupsearch = 0;

Getopt::Long::GetOptions
(
    \%optctl,
    "server=s",
    "secret=s",
    "dn=s",
    "userbase=s",
    "groupbase=s",
    "uid=s",
    "cn=s",
);


if ($optctl{secret}) { $secret = $optctl{secret}; }
if ($optctl{server}) { $server = $optctl{server}; }
if ($optctl{dn}) { $dn = $optctl{dn}; }
if ($optctl{userbase}) { $userbase = $optctl{userbase}; }
if ($optctl{groupbase}) { $groupbase = $optctl{groupbase}; }
if ($optctl{uid}) { $uid = $optctl{uid}; $dousersearch = 1; }
if ($optctl{cn}) { $cn = $optctl{cn}; $dogroupsearch = 1; }


#print "secret : $secret\n";
#print "server : $server\n";
#print "dn : $dn\n";
#print "userbase : $userbase\n";
#print "groupbase : $groupbase\n";
#print "uid : $uid\n";
#print "cn : $cn\n";

my $ldap = Net::LDAP->new($server) or die "LDAP FAILED\n$@";

#my $ldap = Net::LDAP->new($server) or die "LDAP FAILED\n$!";

my $ldap_secret;

#print "secret : $secret\n";

if (-f $secret)
{
	print "Validating Secret File : '$secret'..";
    open(F,"<$secret") or die "LDAP FAILED\ncould not open $secret\n";

    $ldap_secret=sprintf("%s", <F>);
    chomp($ldap_secret);
    close F;
	print "\tDone!\n";
}
else
{
    $secret = '';
}


# bind to a directory with dn and password
#print "\tbinding..";
if ($ldap_secret)
{
	#my  $mesg = $ldap->bind( $dn, password => $secret);
	my $mesg=$ldap->bind($dn, password => "$ldap_secret");
	$mesg->code && die "LDAP FAILED\ncould not bind with secret file '$secret' : $mesg->error";
	#print "\tmesg : $mesg!\n";
#	print "\tDone!\n";
}
else
{
	my  $mesg = $ldap->bind();
	$mesg->code && die "LDAP FAILED\ncould not bind anonymous : $mesg->error";

	print "\tDone!\n";
}

if ($dousersearch)
{
#	print "\tuser search..";
	my $mesg = $ldap->search(base => "$userbase", scope   => "sub", filter  => "uid=$uid",);
	$mesg->code && die "LDAP FAILED\ncould not search tree $dn\n";;

	print "\tDone!\n";
}


if ($dogroupsearch)
{
	print "\tgroup search..";
	my $mesg = $ldap->search(base => "$groupbase", scope   => "sub", filter  => "cn=$cnd",);
	$mesg->code && die "LDAP FAILED\ncould not search tree $dn\n";;
	print "\tDone!\n";
}

#print "\tunbinding..";
$mesg = $ldap->unbind;  # take down session
$mesg->code && die "LDAP FAILED\ncould not unbind $dn\n";;

#print "\tDone!\n";

exit 0;
