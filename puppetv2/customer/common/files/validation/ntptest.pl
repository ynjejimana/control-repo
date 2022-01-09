#!/usr/bin/perl


use strict; use warnings;

use Data::Dumper;
use Getopt::Long;
use Net::NTP;
use Time::HiRes qw( time ); 

my $server= shift @ARGV;
my $comment = join(' ', @ARGV);

if (!$server)
{
    die "usage : $0 [host]\n";
}

my $detail = undef;
my $limit = 1;#1 sec 

my $bad = undef; 
my $t0 = time; 
my %h = get_ntp_response($server);

#Timestamp Name ID When Generated
#------------------------------------------------------------
#Originate Timestamp T1 time request sent by client
#Receive Timestamp T2 time request received by server
#Transmit Timestamp T3 time reply sent by server
#Destination Timestamp T4 time reply received by client
#
#The roundtrip delay d and local clock offset t are defined as
#
#d = (T4 - T1) - (T2 - T3) t = ((T2 - T1) + (T3 - T4)) / 2

my $T1 = $t0; # $h{'Originate Timestamp'};
my $T2 = $h{'Receive Timestamp'};
my $T3 = $h{'Transmit Timestamp'};

my $T4 = time; # From Time::HiRes! Accurate to usec!

#print "T4=$T4\n";
my $d = ($T4 - $T1) - ($T2 - $T3);
my $t = (($T2 - $T1) + ($T3 - $T4)) / 2;
my $duration = $T4-$t0;
my $delta = $T2-$T1 - $duration/2;

if( $limit ) {
	if( $delta > $limit || -$delta < -$limit) {
		print "Server $server OFF by $delta seconds!!!\n";
		$bad = 1;
	} else {
		print "Server $server OK, delta is $delta seconds!!!\n";
	}

} else {
	if( $detail ) {
		print Dumper( \%h ) . "\nt0=$t0, T4=$T4\ndelay=$d, offset=$t\nelapsed=$duration, delta=$delta\n\n";
	} else {
		#print "$server delay=$d, offset=$t, delta=$delta, duration=$duration\n";
		print sprintf( "%-30s %.5f\n", $server, $t );
	}
} 
