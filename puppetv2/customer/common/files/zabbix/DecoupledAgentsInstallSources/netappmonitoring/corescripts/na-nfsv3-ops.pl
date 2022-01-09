#!/usr/bin/perl -w

#require 5.6.1;
use lib "./NetApp"; 

use NaServer;
use NaElement;

use Getopt::Long;

use Data::Dumper;

my $server = "storage3";
my $username = "root";
my $password = "netapp1" ;

GetOptions (
		"server=s" => \$server,
		"username=s"   => \$username,
		"password=s"  => \$password
	);

# nearly all Filers should provide this counter
my $s = NaServer->new($server, 1, 7);

# set our login details
$s->set_style(LOGIN_PASSWORD);
$s->set_admin_user($username, $password);

# note that this will only work with http, change the below if you
# use https
$s->set_transport_type("HTTPS");

# create the request to the iscsi object
my $request = NaElement->new('perf-object-get-instances');
$request->child_add_string('objectname', 'nfsv3');

# the counter container
my $counters = NaElement->new('counters');

# operations counters
$counters->child_add_string('counter', 'nfsv3_ops');
$counters->child_add_string('counter', 'nfsv3_read_ops');
$counters->child_add_string('counter', 'nfsv3_write_ops');
$counters->child_add_string('counter', 'nfsv3_read_latency');
$counters->child_add_string('counter', 'nfsv3_write_latency');

$request->child_add($counters);

# gimmie, gimmie
my $out = $s->invoke_elem($request);
my $results = $out->child_get('instances')->child_get('instance-data')->child_get('counters');

# print off our results in a cacti friendly format
foreach ($results->children_get()) {
	print $_->child_get_string('name') . ":" . $_->child_get_string('value') . " ";
}

print "\n";
