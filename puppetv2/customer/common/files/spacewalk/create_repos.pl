#!/usr/bin/perl -w

    use strict;
    use Frontier::Client;
    use Data::Dumper;
    use warnings;


    my $repo_cfg = 'repos.cfg';

    my $satellite = 'localhost';

    if ( $#ARGV != 1 ) {
        print "ERROR - Usage: create_repos.pl username password \n";
        exit;
    }


    my $user = "$ARGV[0]";
    my $password = "$ARGV[1]";

    my $client = new Frontier::Client(url => "http://$satellite/rpc/api");
    my $session = $client->call('auth.login', $user, $password);


    open my $fh, '<', "$repo_cfg" or die $!;
    while( <$fh> ) {
        chomp;   # strip trailing linefeed from $_
        next if /^(\s*(#.*)?)?$/;
	my $repoitem = $_;

        my @repoarray = split('\|',$_);
	next if ( $#repoarray != 5 );
	
        my $vendor = $repoarray[0];
        my $version = $repoarray[1];
        my $repo_arch = $repoarray[2];
        my $repo_id = $repoarray[3];
        my $repo_type = $repoarray[4];
        my $repo_url = $repoarray[5];

	my $repo_label = "$vendor-$version-$repo_arch-$repo_id";
	print "Createing repository: $repo_label ...\n";


        eval { $client->call('channel.software.createRepo',
		"$session",
		"$repo_label",
		"$repo_type",
		"$repo_url",
	);
	};
	print "Warning: repository might be already created with the same name: $repo_label...\n" if $@;

    }

    close $fh;



$client->call('auth.logout', $session);

