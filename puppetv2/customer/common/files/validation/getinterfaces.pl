#!/usr/bin/perl

use strict;

my $ifconfigcmd = "ifconfig -a | grep Link | awk '{ print \$1}'";

our @interfaces = @ARGV;
our @interfacelist;


open (IF, "$ifconfigcmd |") || die "can not run ifconfig.. : $!\n";

while(<IF>)
{
#    print $_;
    chop;
    push @interfacelist, $_;
}

close IF;

#print "\tinterface:\n";

checkintinlist(@interfaces);
exit 0;

sub checkintinlist
{
    my @checkints = @_;

    foreach my $int (@checkints)
    {
        print "$int..";
        my (@found) = grep(/^$int$/, @interfacelist);
        #print "found : @found!\n";
        if (@found)
        {
            print "FOUND!\n";
        }
        else
        {
            print "NOT FOUND!\n";
        }
    }
}


