#!/us/bin/perl

use strict;
use Net::Ping;

my $host = shift @ARGV;
my $comment = join(' ', @ARGV);

if (!$host)
{
    die "usage : $0 [host]\n";
}

#my $p = Net::Ping->new("icmp");
my $p = Net::Ping->new();

if ($p->ping($host))
{
    if (!$comment)
    {
        print "ping $host TRUE\n"
    }
    else
    {
        print "ping $host ($comment) TRUE\n"
    }
}
else
{

    if (!$comment)
    {
        print "ping $host FALSE\n"
    }
    else
    {
        print "ping $host ($comment) FALSE\n"
    }
}

$p->close();
