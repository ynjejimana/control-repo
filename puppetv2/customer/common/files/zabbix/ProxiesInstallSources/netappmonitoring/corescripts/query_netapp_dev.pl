#!/usr/bin/perl -w
#
# na-realtime-vol-latency.pl - written by Andrew Sullivan, 2009-06-23
#
# Please report bugs and request improvements at http://get-admin.com/blog/?p=763
#
# This script will query a NetApp appliance using the OnTAP SDK to get different
# protocol latencies for the specified volume.
#
#  na-realtime-nfs-latency.pl --hostname|-H <hostname> 
#            --username|-u <username> 
#            --password|-p <password> 
#            --volume|-v <volume_name>
#          [ --protocol|-P all|nfs|cifs|san|fcp|iscsi ]
#          [ --interval|-i <seconds_between_polling> ]
#          [ --noread, --nowrite, --noother, --noaverage, --noops ]
#
#  Password is optional, if it is not supplied at the command line the script
#  will prompt for it.
#
#  If "average" is requested (it's turned on by default) it is the average
#  latency (and total operations) for all protocols.
#
#  By default read, write, other, and average latencies are displayed for
#  the specified protocol.  You can turn them off by passing "--no<op_type>".
#  If no protocol is specified, "all" is the default (which is the sum of all 
#  the protocols respective read/write/other operations).
#
#  There is a delay of <interval> before the first set of results is displayed.
#  This is perfectly normal.
#  
# Examples:
#  na-realtime-vol-latency.pl --hostname toaster --username not_root --interval 10
#
#  Same as above, but with the abbreviated options, and not displaying the average
#  na-realtime-vol-latency.pl -H toaster -u not_root -i 10 --noaverage
#
#  Display only read and write cifs operations/latency
#  na-realtime-vol-latency.pl -H toaster -u not_root -i 10 --noaverage --noother -P cifs
#
# TODO:
#	Find a good way to print multiple volumes.  The inital part is here (the script will
#		accept a comma separated list of volumes, but only uses the first supplied), I 
#		just don't know of a good, readable, way to print the data.
#
 
# I placed the NetApp perl modules into my perl lib directory, however,
# if you haven't done this, you will probably need to specify where they
# are using a lib declaration
#use lib "./NetApp";

use Data::Dumper;

BEGIN {

        push @INC,"/etc/zabbix/NetApp/NetApp";

        }

use lib "NetApp";
use NaServer;
use NaElement;
 
use Getopt::Long qw(:config no_ignore_case);
 
main( );
 
sub main {
	my $opts = parse_options();
	my $server = get_filer( $opts->{ 'hostname' }, $opts->{ 'username' }, $opts->{ 'password' } );
 
	my $first = get_latency( $server, $opts );

 	sleep $opts->{ 'interval' };
 
	my $second = get_latency( $server, $opts );

	# check to make sure the user provided a valid vol name
	if ( scalar( keys %$first ) == 0 ) {
		print "Volume " . @{ $opts->{'volume'} }[0] . " not found!\n";
		exit(1);
	}
 
	# retrieve the column headers and the printf formatter for the values
	my ($header, $printf) = build_header( $opts );
 
#	print $header;


	foreach (@{$opts->{'volume'}})
        {
		$volume = $_;
		
		my $read_latency = 0;
		my $write_latency = 0;
		my $other_latency = 0;
		my $avg_latency = 0;
 
		my $read_ops = 0;
		my $write_ops = 0;
		my $other_ops = 0;
		my $total_ops = 0;
 
		my @values;
		# check to see if this was a selected value, if so, make sure that we have > 0 ops that
		# occurred and do the simple math to get our values
		
		if ($opts->{'average'} && $second->{'total_ops-'.$volume} > $first->{'total_ops-'.$volume}) {
			$total_ops = $second->{'total_ops-'.$volume} - $first->{'total_ops-'.$volume};
			$avg_latency = ($second->{'avg_latency-'.$volume} - $first->{'avg_latency-'.$volume}) / $total_ops;
		}
 
		# if this was in the above statement, and there was no operations, then the "0" value 
		# would not get inserted into the values array
		push(@values, $avg_latency) if $opts->{'average'};
		push(@values, $total_ops) if $opts->{'ops'} && $opts->{'average'};
 
		if ($opts->{'read'} && $second->{'read_ops-'.$volume} > $first->{'read_ops-'.$volume}) {
			$read_ops = $second->{'read_ops-'.$volume} - $first->{'read_ops-'.$volume};
			$read_latency = ($second->{'read_latency-'.$volume} - $first->{'read_latency-'.$volume}) / $read_ops;
		}
 
		push(@values, $read_latency) if $opts->{'read'};
		push(@values, $read_ops) if $opts->{'ops'} && $opts->{'read'};
 
		if ($opts->{'write'} && $second->{'write_ops-'.$volume} > $first->{'write_ops-'.$volume}) {
			$write_ops = $second->{'write_ops-'.$volume} - $first->{'write_ops-'.$volume};
			$write_latency = ($second->{'write_latency-'.$volume} - $first->{'write_latency-'.$volume}) / $write_ops;
		}
 
		push(@values, $write_latency) if $opts->{'write'};
		push(@values, $write_ops) if $opts->{'ops'} && $opts->{'write'};
 
 
		if ($opts->{'other'} && $second->{'other_ops-'.$volume} > $first->{'other_ops-'.$volume}) {
			$other_ops = $second->{'other_ops-'.$volume} - $first->{'other_ops-'.$volume};
			$other_latency = ($second->{'other_latency-'.$volume} - $first->{'other_latency-'.$volume}) / $other_ops;
		}
 
		push(@values, $other_latency) if $opts->{'other'};
		push(@values, $other_ops) if $opts->{'ops'} && $opts->{'other'};
 
		print  $volume." | ";
		printf $printf, @values;
		print "\n";
 
#		$first = $second;
 
	}
}
 
### Supporting subroutines ###
 
#
# Prints the usage information
#
sub print_usage {
	print <<EOU
  Missing or incorrect arguments!
 
  na-realtime-nfs-latency.pl --hostname|-H <hostname> 
            --username|-u <username> 
            --password|-p <password> 
            --volume|-v <volume_name>
          [ --protocol|-P all|nfs|cifs|san|fcp|iscsi ]
          [ --interval|-i <seconds_between_polling> ]
          [ --noread, --nowrite, --noother, --noaverage, --noops ]
 
  na-realtime-nfs-latency.pl --help|-h
 
EOU
 
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
		'volume'   => [],
		'protocol' => 'all',
		'average'  => 1,
		'read'     => 1,
		'write'    => 1,
		'other'    => 1,
		'ops'      => 1,
		'help'     => 0
	);
 
	GetOptions( \%options,
		'hostname|H=s',
		'username|u=s',
		'password|p:s',
		'interval|i:i',
		'volume|v=s',
		'protocol|P:s',
		'average!',
		'read!',
		'write!',
		'other!',
		'ops!',
		'help|h'
	);
 
	# if the user supplied a comma separated list of volumes to get data for, we split them
	# into an array here...
	@{$options{ 'volume' }} = split( /,/, join( ',', @{$options{ 'volume' }} ) );
 
	# make sure we have a hostname, username, at least 1 volume and protocol is a valid
	# value.  if any of those are not true, or the user requested help, print the help.
	if ( ! $options{ 'hostname' }              || ! $options{ 'username' } || 
	     scalar( @{$options{ 'volume' }} ) < 1 || $options{ 'help' }       ||
		 ! $options{ 'protocol' } =~ /(?:all|nfs|cifs|san|fcp|iscsi)/i 
		) {
 
		print_usage();
		exit(1);
	}
 
	# I'm putting the requested displays into an array so that I can loop through them.
	# This should enable me to shorten the code later.
	my @requested;
 
	push(@requested, 'average') if $options{'average'};
	push(@requested, 'read') if $options{'read'};
	push(@requested, 'write') if $options{'write'};
	push(@requested, 'other') if $options{'other'};
 
	$options{'requested'} = \@requested;
 
	# if we didn't get passed a password, prompt for one
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
#	$s->set_transport_type(NA_SERVER_TRANSPORT_HTTP);
        $s->set_transport_type("HTTPS");

	#$out = $s->set_transport_type();
	#print "out : $out\n";
	#if (ref ($out) eq "NaElement") { 
	#	if ($out->results_errno != 0) {
	#		my $r = $out->results_reason();
	#		print "Failed: $r\n";
	#	}
	#}
 
	return $s;
}
 
# 
# Queries the NetApp and returns a hash of responses
#
sub get_latency {
	my ($server, $opts) = @_;
 
	# Initialize the return hash so that it contains values.
	# This prevents a bug found by Steffen Nagel where perl will
	# display errors when trying to do math on values that don't exist
	# because they were not returned by the toaster.
	# See http://get-admin.com/blog/?p=763#comment-715
	my $return = {
#		'volume'        => "nil",
#		'avg_latency'   => 0,
#		'total_ops'     => 0,
#		'read_latency'  => 0,
#		'read_ops'      => 0,
#		'write_latency' => 0,
#		'write_ops'     => 0,
#		'other_latency' => 0,
#		'other_ops'     => 0
	};
 
	my $request = build_request( $opts );
	my $result = $server->invoke_elem( $request );

#REMOVE ME 
#foreach ($result->child_get('instances')->children_get())
#{   
#    print "==>".$_->child_get_string('name')."\n";
#
#     
#}
#REMOVE ME

#print Dumper($result);

	if ( scalar( $result->child_get('instances')->children_get() ) > 0 ) 
	{
 
		foreach ($result->child_get('instances')->children_get())
		{	
#			 print "==>".$_->child_get_string('name')."\n";

			$volume = $_->child_get_string('name');
			$return->{ 'volume-'.$volume } = $volume;

			my $instance_data = $_;
			foreach ($instance_data->child_get('counters')->children_get()) 
			{
				my $name = $_->child_get_string('name');
 
				# strip off the protocol name so that they are always the same, this makes
				# it easy to retrieve them during display back cause we don't have to 
				# account for the different names
				$name =~ s/(?:nfs|cifs|san|fcp|iscsi)_//;
#				 print "----".$name."\n";			

				$return->{ $name."-".$volume } = $_->child_get_string('value');
			}
		}
	}
 
#while ( my ($key, $value) = each(%$return) ) {
#        print "$key => $value\n";
#    }
	return $return;
}
 
# 
# creates the NaElement tree for querying latency
#
sub build_request {
	my $opts = shift;
 
	# each of the different protocols on the volume has it's own read, write
	# and other counters.  Average is the odd-man-out, as it is a summary of
	# all of the protocols, so we compensate with a check in the loop below
	my $counter_names = {
		'average' =>   [ 'avg_latency',        'total_ops' ],
		'read' => {
			'all'   => [ 'read_latency',       'read_ops' ],
			'nfs'   => [ 'nfs_read_latency',   'nfs_read_ops' ],
			'cifs'  => [ 'cifs_read_latency',  'cifs_read_ops' ],
			'san'   => [ 'san_read_latency',   'san_read_ops' ],
			'fcp'   => [ 'fcp_read_latency',   'fcp_read_ops' ],
			'iscsi' => [ 'iscsi_read_latency', 'iscsi_read_ops' ]
		},
		'write' => {
			'all'   => [ 'write_latency',       'write_ops' ],
			'nfs'   => [ 'nfs_write_latency',   'nfs_write_ops' ],
			'cifs'  => [ 'cifs_write_latency',  'cifs_write_ops' ],
			'san'   => [ 'san_write_latency',   'san_write_ops' ],
			'fcp'   => [ 'fcp_write_latency',   'fcp_write_ops' ],
			'iscsi' => [ 'iscsi_write_latency', 'iscsi_write_ops' ]
		},
		'other' => {
			'all'   => [ 'other_latency',       'other_ops' ],
			'nfs'   => [ 'nfs_other_latency',   'nfs_other_ops' ],
			'cifs'  => [ 'cifs_other_latency',  'cifs_other_ops' ],
			'san'   => [ 'san_other_latency',   'san_other_ops' ],
			'fcp'   => [ 'fcp_other_latency',   'fcp_other_ops' ],
			'iscsi' => [ 'iscsi_other_latency', 'iscsi_other_ops' ]
		}
	};
 
	my $request = NaElement->new('perf-object-get-instances');


	$request->child_add_string('objectname', 'volume');
	my $counters = NaElement->new('counters');
 
	foreach my $r ( @{$opts->{'requested'}} ) {
		if ($r eq "average") {
			foreach ( @{ $counter_names->{'average'} } ) {
				$counters->child_add_string('counter', $_);
			}
		} else {
			foreach ( @{$counter_names->{ $r }->{ $opts->{'protocol'} }} ) {
				$counters->child_add_string('counter', $_);
			}
		}
	}
 
	$request->child_add( $counters );
 
	my $instances = NaElement->new('instances');

        foreach (@{$opts->{'volume'}}) 
	{
		$instances->child_add_string('instance', $_);
	} 
	$request->child_add( $instances );
 
	return $request;
}
 
#
# Builds the "header" line for display back and returns the printf string that
# we will use to print the values returned from our SDK queries in a nicely
# formatted manner
#
sub build_header {
	my $opts = shift;
 
	# the base formatters for the header, note that here is where the pipe
	# character that separates the columns when the ops are displayed is 
	# added in
	my $head_lat_printf = '%14s';
	my $head_ops_printf = '%10s |';
 
	my $head_lat_sep = "-" x 14;
	my $head_ops_sep = "-" x 10;
 
	my @header_printf;
	my @header_values;
	my @separator;
 
	# the column header title values
	my $header_titles = {
		#              Value Title  Ops Title
		'average' => [ 'Avg Lat',   'Total Ops' ],
		'read'    => [ 'Read Lat',  'Read Ops' ],
		'write'   => [ 'Write Lat', 'Write Ops' ],
		'other'   => [ 'Other Lat', 'Other Ops' ]
	};
 
	# the base formatters for the values
	my $lat_printf = '%11.2f usec';
	my $ops_printf = '%10i |';
 
	my @values_printf;
 
	# loop through the reqested displays, adding the data for each
	foreach my $request ( @{$opts->{'requested'}} ) {
		# add the header's print
		push(@header_printf, $head_lat_printf);
 
		# we get the title text from the array reference in the hash above
		push(@header_values, @{ $header_titles->{ $request } }[0]);
 
		# and an unsatisfactory hack to get a separator line...
		push(@separator, $head_lat_sep);
 
		# add the value line's printf
		push(@values_printf, $lat_printf);
 
		if ( $opts->{ 'ops' } ) {
			# header
			push(@header_printf, $head_ops_printf);
			push(@header_values, @{ $header_titles->{ $request } }[1]);
 
			push(@separator, $head_ops_sep);
 
			# values
			push(@values_printf, $ops_printf);
		}
	}
 
	# put the values in the hash
	$t = join(" ", @header_printf);
 
	$header = sprintf( $t, @header_values ) . "\n" . sprintf( $t, @separator ) . "\n";
	$printf = join(" ", @values_printf);
 
	# return the values printf formatter
	return ($header, $printf);
 
}
