#!/usr/bin/perl

use strict;

my $netapp = shift @ARGV;

#print "netapp : $netapp\n";

if (!$netapp)
{
	print STDERR "Usage : $0 [netapp]\n";
	exit 1;
}

my $outputdir="/tmp/netappdata";

system("mkdir -p /tmp/netappdata");

my $datafile="$outputdir/$netapp";

#echo netapp: $netapp

my $volscmd = "ssh $netapp vol status | awk '{print \$1}' | grep -v bit | tr '\\n' ','";

#print "volscmd : $volscmd\n";


#my $vols=`"ssh $netapp vol status | awk '{print $1}' | grep -v bit | tr '\n' ','"`;
my $vols=`$volscmd`;

chop $vols;

#print "VOLS : $vols\n";

my $cmd = "perl /srv/zabbix/etc/NetApp/query_netapp.pl -H $netapp -u root -p netapp01 -v $vols -P nfs -i 1 2> /dev/null";

print "cmd : $cmd\n";

exit 0;

open (VOL, "$cmd |") || die "can not run cmd '$cmd' : $!\n";

my @vols = <VOL>;

close VOL;

open(OUT, ">$datafile" ) || die "can not write $datafile : $!\n";

my ($netapp_volume_average_latency_usec,
        $netapp_volume_total_ops_per_sec,
        $netapp_volume_read_latency_usec,
        $netapp_volume_read_ops_per_sec,
        $netapp_volume_write_latency_usec,
        $netapp_volume_write_ops_per_sec,
        $netapp_volume_other_latency_usec,
	$netapp_volume_other_ops_per_sec) = 0;

foreach my $line (@vols)
{
	my ($volname,
	$volume_average_latency_usec,
	$volume_total_ops_per_sec, 
	$volume_read_latency_usec, 
	$volume_read_ops_per_sec, 
	$volume_write_latency_usec, 
	$volume_write_ops_per_sec, 
	$volume_other_latency_usec,
	$volume_other_ops_per_sec) = $line =~ /(\w+)\s*\|\s*(\d*.\d*)\s*usec\s*(\d*)\s*\|\s*(\d*.\d*)\s*usec\s*(\d*)\s*\|\s*(\d*.\d*)\s*usec\s*(\d*)\s*\|\s*(\d*.\d*)\s*usec\s*(\d*)(.*)/;

	#print "vol : $volname\n";
	#print "volume_average_latency_usec : '$volume_average_latency_usec'\n";
	#print "volume_total_ops_per_sec : '$volume_total_ops_per_sec'\n";
	#print "volume_read_latency_usec : '$volume_read_latency_usec'\n";
	#print "volume_read_ops_per_sec : '$volume_read_ops_per_sec'\n";
	#print "volume_write_latency_usec : '$volume_write_latency_usec'\n";
	#print "volume_write_ops_per_sec : '$volume_write_ops_per_sec'\n";
	#print "volume_other_ops_per_sec : '$volume_other_ops_per_sec'\n";
	#print "volume_other_latency_usec : '$volume_other_latency_usec'\n";

	print OUT "$volname | ";
	print OUT "$volume_average_latency_usec usec ";
	print OUT "$volume_total_ops_per_sec | ";
	print OUT "$volume_read_latency_usec usec ";
	print OUT "$volume_read_ops_per_sec | ";
	print OUT "$volume_write_latency_usec usec ";
	print OUT "$volume_write_ops_per_sec | ";
	print OUT "$volume_other_latency_usec usec ";
	print OUT "$volume_other_ops_per_sec\n";

	$netapp_volume_average_latency_usec+=$volume_average_latency_usec;

        $netapp_volume_total_ops_per_sec+=$netapp_volume_total_ops_per_sec;

	$netapp_volume_read_latency_usec+=$volume_read_latency_usec;

	$netapp_volume_read_ops_per_sec+=$volume_read_ops_per_sec;

	$netapp_volume_write_latency_usec+=$volume_write_latency_usec; 

	$netapp_volume_write_ops_per_sec+=$volume_write_ops_per_sec;

	$netapp_volume_other_latency_usec+=$volume_other_latency_usec;

	$netapp_volume_other_ops_per_sec+=$volume_other_ops_per_sec;

}

print OUT "TOTAL | ";
print OUT "$netapp_volume_average_latency_usec usec ";
print OUT "$netapp_volume_total_ops_per_sec | ";
print OUT "$netapp_volume_read_latency_usec usec ";
print OUT "$netapp_volume_read_ops_per_sec | ";
print OUT "$netapp_volume_write_latency_usec usec ";
print OUT "$netapp_volume_write_ops_per_sec | ";
print OUT "$netapp_volume_other_latency_usec usec ";
print OUT "$netapp_volume_other_ops_per_sec\n";

close OUT;

exit 0;
