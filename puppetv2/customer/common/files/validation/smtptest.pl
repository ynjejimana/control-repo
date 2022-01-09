#!/usr/bin/perl

use Test::SMTP qw(plan);

my $server= shift @ARGV;
my $mailfrom = shift @ARGV;
my $rcptto =  shift @ARGV;

if (!$server)
{
    die "usage : $0 [host] [test from@address] [test rcptto@address]\n";
}


if (!$mailfrom)
{
    die "usage : $0 [host] [test from@address] [test rcptto@address]\n";
}

if (!$rcptto)
{
    die "usage : $0 [host] [test from@address] [test rcptto@address]\n";
}

plan tests => 5;
# Constructors
print STDOUT "Test connect to mailhost : $server\n";
my $client1 = Test::SMTP->connect_ok('connect to mailhost',
				 Host => $server, AutoHello => 1);

print STDOUT "Test Mail From : $mailfrom\n";
$client1->mail_from_ok($mailfrom, 'Accept an example mail from');

print STDOUT "Test RCPT TO : $rcptto\n";
$client1->rcpt_to_ko($rcptto, 'Reject an example domain in rcpt to');

$client1->quit_ok('Quit OK');
my $client2 = Test::SMTP->connect_ok('connect to mailhost',
				 Host => '127.0.0.1', AutoHello => 1);
