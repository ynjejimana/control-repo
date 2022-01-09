#!/usr/bin/perl

use Net::DNS;

#my $testaddress = "srdcinf2.oraclesrdc.com";
my $testaddress = shift @ARGV;

if (!$testaddress)
{
    $testaddress = "srdcinf2.oraclesrdc.com";
}

print "Testing DNS\tusing $testaddress..";
my $res   = Net::DNS::Resolver->new;
my $query = $res->search($testaddress);

if ($query)
{
      print "Found!\tTRUE\n";
}
else
{
      print "NOT Found! ", $res->errorstring, "\tFALSE\n";
}
