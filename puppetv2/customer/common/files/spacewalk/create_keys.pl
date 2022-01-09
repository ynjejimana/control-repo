#!/usr/bin/perl -w

    use strict;
    use Frontier::Client;
    use Data::Dumper;
    use warnings;


    my $keys_cfg = 'keys.cfg';

    my $satellite = 'localhost';

    if ( $#ARGV != 1 ) {
        print "ERROR - Usage: create_keys.pl username password \n";
        exit;
    }

    my $user = "$ARGV[0]";
    my $password = "$ARGV[1]";

    my $client = new Frontier::Client(url => "http://$satellite/rpc/api");
    my $session = $client->call('auth.login', $user, $password);


    open my $fh, '<', "$keys_cfg" or die $!;
    while( <$fh> ) {
        chomp;   # strip trailing linefeed from $_
        next if /^(\s*(#.*)?)?$/;
	my $keyitem = $_;

        my @keyarray = split('\|',$_);
	
        my $key_label = "$keyarray[0]";
	my $key_desc = ($keyarray[1])? "$keyarray[1]" : "$key_label";
	my $key_base_channel = ($keyarray[2])? "$keyarray[2]" : "";
	my $key_children = ($keyarray[3])? "$keyarray[3]" : "";
	my $empty = "";
	my $default_key;
	my @perm = [ "provisioning_entitled" ];

	print "Creating activation keys: $key_label ...\n";

	eval {   $client->call('activationkey.create',
                 $session,
                 "$key_label",
                 "$key_desc",
                 "$key_base_channel",
		 @perm,
		 $client->boolean(0),
        );
	};
	print "Warning: keys might be already created with the same label: $key_label...($@)\n" if $@;





# adding children channels to the key
	my @children = split('\,',$key_children);
	print "--> Adding channels...\n";
	eval {
		$client->call('activationkey.addChildChannels',
               	$session,
               	"1-$key_label",
               	\@children,
        	);
	};
	print "Warning: cannot add child channel to the key ($@)\n" if $@;

    }

    close $fh;



$client->call('auth.logout', $session);

