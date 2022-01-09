#!/usr/bin/perl -w


    use strict;
    use Frontier::Client;
    use Data::Dumper;
    use warnings;


    my $orgs_cfg = 'orgs.cfg';

    my $satellite = 'localhost';

    if ( $#ARGV != 1 ) {
        print "ERROR - Usage: create_orgs.pl username password \n";
        exit;
    }

    my $user = "$ARGV[0]";
    my $password = "$ARGV[1]";


    my $client = new Frontier::Client(url => "http://$satellite/rpc/api");
    my $session = $client->call('auth.login', $user, $password);


    open my $fh, '<', "$orgs_cfg" or die $!;
    while( <$fh> ) {
        chomp;
        next if /^(\s*(#.*)?)?$/;
	my $orgitem = $_;

        my @orgarray = split('\|',$orgitem);
#	next if ( $#orgarray != 4 );
	
        my $org_label = "$orgarray[0]";
	my $org_admin = ($orgarray[1])? "$orgarray[1]" : "${org_label}-admin";
	my $org_pass = ($orgarray[2])? "$orgarray[2]" : "$org_admin";
	my $org_email = ($orgarray[3])? "$orgarray[3]" : "${org_admin}\@${org_label}.com";
	my $org_res;
	print "Creating org: $org_label \n";
	print " ... Administrator user  : $org_admin \n";
	print " ... Administrator pass  : $org_pass \n";
	print " ... Administrator email : $org_email \n\n";

	eval {   $org_res = $client->call('org.create',
                 $session,
                 "$org_label",
                 "$org_admin",
                 "$org_pass",
		 "Mr.",
		 "$org_admin",
		 "$org_label",
		 "$org_email",
		 $client->boolean(0),
        );
	};
	print "Warning: ($@)\n" if $@;

	eval { $client->call('org.trusts.addTrust',
		$session,
		"1",
		"$org_res->{id}",
	);
	};
	print "Cannot add trusts\n" if $@;

    }

    close $fh;



$client->call('auth.logout', $session);

