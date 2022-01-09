#!/usr/bin/perl -w
#
# na-realtime-nfs-latency.pl - written by Andrew Sullivan, 2009-06-23
#
# Please report bugs and request improvements at http://get-admin.com/blog/?p=758
#
# I wanted a way to see the realtime nfs latency as reported by a NetApp 
# appliance.  This perl script uses the OnTAP SDK to query the NetApp for
# the performance stats and display back the latency and operations performed.
#
# The latency is found by measuring the total latency and total ops at two 
# intervals.  The first set of values is subtracted from the second, and then
# the ops are divided into the total latency giving us average latency.
#
# Examples:
#   This will query the appliance every 15 seconds to display the latency.  I don't
#   provide a password because it will ask for one if it's not provided.
#     na-realtime-nfs-latency.pl --hostname toaster --username not_root --interval 10
#
#   Same as above, but with the abbreviated options
#     na-realtime-nfs-latency.pl -H toaster -u not_root -i 10
#
# TODO:
#   Modify to work for all versions of NFS, not just 3
#
 
# I placed the NetApp perl modules into my perl lib directory, however,
# if you haven't done this, you will probably need to specify where they
# are using a lib declaration
use lib "NetApp";
use NaServer;
use NaElement;
 
use Getopt::Long qw(:config no_ignore_case);
 
main( );
 
sub main {
	my $opts = parse_options();
	my $server = get_filer( $opts->{ 'hostname' }, $opts->{ 'username' }, $opts->{ 'password' } );
 
	# print a nice header 
	#printf '%14s %10s %14s %10s', "Read Latency", "Read Ops", "Write Latency", "Write Ops";
	#print "\n" . "-" x 14 . " " . "-" x 10 . " " . "-" x 14 . " " . "-" x 10 . "\n";
 
	# initialize the first data set
	my $first = get_latency( $server );
 
#	while (1) 
	{
		# zeroize the counters
		my $nfs_read_latency = 0;
		my $nfs_write_latency = 0;
		my $nfs_read_ops = 0;
		my $nfs_write_ops = 0;
 
		# wait the specified amount 
		sleep $opts->{ 'interval' };
 
		# gather the second set of values
		my $second = get_latency( $server );
 
		# check to make sure we don't divide by zero
		if ($second->{'avg_read_latency_base'} > $first->{'avg_read_latency_base'}) {
			$nfs_read_ops = $second->{'avg_read_latency_base'} - $first->{'avg_read_latency_base'};
			$nfs_read_latency = ($second->{'read_latency'} - $first->{'read_latency'}) / $nfs_read_ops;
		}
 
		if ($second->{'avg_write_latency_base'} > $first->{'avg_write_latency_base'}) {
			$nfs_write_ops = $second->{'avg_write_latency_base'} - $first->{'avg_write_latency_base'};
			$nfs_write_latency = ($second->{'write_latency'} - $first->{'write_latency'}) / $nfs_write_ops;
		}
 
		# print the data
		printf "Read Latency:%f\nRead Ops:%i\nWrite Latency:%f\nWrite Ops:%i\n", $nfs_read_latency, $nfs_read_ops, $nfs_write_latency, $nfs_write_ops;
 
		# shift our values
		$first = $second;
 
	}
}
 
### Supporting subroutines ###
 
#
# Prints the usage information
#
sub print_usage {
	print <<EOL
  Missing or incorrect arguments!
 
  na-realtime-nfs-latency.pl --hostname|-H <hostname> 
            --username|-u <username> 
          [ --password|-p <password> ]
          [ --interval|-i <seconds_between_polling> ]
 
  na-realtime-nfs-latency.pl --help|-h
 
  It is not necessary to supply a password during the command line
  call.  If it is not provided, it will be asked for.
 
EOL
 
}
 
#
# Defines and parses the options from the command line, also
# checks to make sure that options are valid.  Will prompt for
# a password if one is not provided.
#
sub parse_options {
 
	my %options = (
		'hostname' => '',
		'username' => '',
		'password' => '',
		'interval' => 30,
		'help'     => 0
	);
 
	GetOptions( \%options,
		'hostname|H=s',
		'username|u=s',
		'password|p:s',
		'interval|i:i',
		'help|h'
	);
 
	if (! $options{ 'hostname' } || ! $options{ 'username' } || $options{ 'help' }) {
		print_usage();
		exit(1);
	}
 
	if (! $options{ 'password' }) {
		print "Enter password: ";
		if ( $^O eq "MSWin32" ) {
			require Term::ReadKey;
 
			Term::ReadKey->import( qw(ReadMode) );
			Term::ReadKey->import( qw(ReadLine) );
			ReadMode('noecho');
 
			chomp( $options{ 'password' } = ReadLine(0) );
 
			ReadMode('normal');
 
		} else {
			system("stty -echo") and die "ERROR: stty failed\n";
 
			chomp ( $options{ 'password' } = <STDIN> );
 
			system("stty echo") and die "ERROR: stty failed\n";
 
		}
 
		print "\n";
	}
 
	return \%options;
}
 
#
# Creates the NaServer object
#
sub get_filer {
	my ($hostname, $username, $password) = @_;
 
	my $s = NaServer->new($hostname, 1, 7);
	$s->set_style(LOGIN_PASSWORD);
	$s->set_admin_user($username, $password);
	$s->set_transport_type("HTTPS");
 
	return $s;
}
 
# 
# Queries the NetApp and returns a hash of responses
#
sub get_latency {
	my $server = shift;
	my $return = {};
 
	my $request = build_request();
	my $result = $server->invoke_elem( $request );
 
	foreach ($result->child_get('instances')->child_get('instance-data')->child_get('counters')->children_get()) {
		my $name = $_->child_get_string('name');
		$name =~ s/nfsv[2|3|4]_//;
 
		$return->{ $name } = $_->child_get_string('value');
	}
 
	return $return;
}
 
# 
# creates the NaElement tree for querying latency
#
sub build_request {
	my $request = NaElement->new('perf-object-get-instances');
	$request->child_add_string('objectname', 'volume');
 
	my $counters = NaElement->new('counters');
 
	$counters->child_add_string('counter', 'avg_latency');
	#$counters->child_add_string('counter', 'nfsv3_read_latency');
	#$counters->child_add_string('counter', 'nfsv3_write_latency');
	#$counters->child_add_string('counter', 'nfsv3_avg_read_latency_base');
	#$counters->child_add_string('counter', 'nfsv3_avg_write_latency_base');
 
	$request->child_add( $counters );
 
	return $request;
}
