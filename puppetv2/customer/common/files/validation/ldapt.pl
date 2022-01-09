#!/usr/bin/perl

use Net::LDAP;

print "server : $server\n";
my $ldap = Net::LDAP->new('ldap.harbour') or die "LDAP FAILED\n$!";
print "Done\n";
