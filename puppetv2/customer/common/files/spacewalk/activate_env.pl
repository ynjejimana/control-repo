#!/usr/bin/perl -w

use strict;
use warnings;

my $sw_command = "/usr/bin/spacewalk-manage-channel-lifecycle";
my $sw_server = "localhost";

if ( $#ARGV != 1 ) {
	print "ERROR - Usage: activate_env.pl username password \n";
	exit;
}

my $user = quotemeta("$ARGV[0]");
my $password = quotemeta("$ARGV[1]");

my $env_list_raw = `cat ~/.spacewalk-manage-channel-lifecycle/settings.conf | grep phases | cut -d"=" -f 2`;
if ($env_list_raw eq "") {
	print "Nothing to do. Exitting...";
	exit 1;
}

my @base_channels = `spacewalk-remove-channel -l | grep "^[a-z]"`;

my @env_items = split('\,',$env_list_raw);


for (my $i=0; $i <= $#env_items; $i++) {
	my $env_item = $env_items[$i];
	chomp $env_item;
	$env_item =~ s/^\s+|\s+$//g;
	my $env_preffix;
	my $method;

	print "Adding environment: ${env_item} ...\n";
	foreach my $base_channel (@base_channels) {
		chomp $base_channel;
		if ( grep( /^$env_item/, @base_channels ) ) {
			print "${env_item}-${base_channel} is already in the configuration - skipping ...\n";
		}
		else {
			print "\t Creating: ${env_item}-${base_channel} ...\n";

			if ($i == 0) {
				$method = 'init';
				$env_preffix = "";
			}
			else {
				$method = 'promote';
				$env_preffix = $env_items[$i-1];
				chomp $env_preffix;
        			$env_preffix =~ s/^\s+|\s+$//g;
				$env_preffix = "${env_preffix}-";
			}

			my $cmd = "${sw_command} -c ${env_preffix}${base_channel} -s ${sw_server} -u ${user} -p ${password} --${method}";

			system("$cmd");
		}
	}

}


#while (@env_items) {
#	my $env_item = shift(@env_items);
#	chomp $env_item;
#	$env_item =~ s/^\s+|\s+$//g;
#	my $init_env = 1;
#	my $env_pref = "${env_item}-";
#
#	print "Adding environment: $env_item...\n";
#	foreach my $base_channel (@base_channels) {
#		chomp $base_channel;
#		next if ($base_channel =~ m/^$env_pref/);
#		print "\tCreating: $base_channel...\n";
#
#		my $method;
#
#		if ($init_env == 1) {
#			$method = 'init';
#		}
#		else {
#			$method = 'promote';
#		}
#
#		my $cmd = "${sw_command} -c ${base_channel} -s ${sw_server} -u ${user} -p ${password} --${method}";
#		print ">$cmd<\n";
#		
#		system("/bin/ls","/") 
#
#		or {
#			print "Cannot create $env_item environment for $base_channel - $?...\n";
#		}
#
#		$init_env++;
#	}

#}


