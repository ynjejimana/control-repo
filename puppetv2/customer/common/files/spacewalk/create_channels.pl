#!/usr/bin/perl -w

    use strict;
    use Frontier::Client;
    use Data::Dumper;
    use warnings;


    my $channel_cfg = 'channels.cfg';

    my $satellite = 'localhost';

    if ( $#ARGV != 1 ) {
        print "ERROR - Usage: create_channels.pl username password \n";
        exit;
    }

    my $user = "$ARGV[0]";
    my $password = "$ARGV[1]";


    my $gpg_path = '/etc/pki/rpm-gpg/';
#    my $gpg_link = "http://$satellite/pub/gpg_keys/";
    my $gpg_link = "file:///etc/pki/rpm-gpg/";

    my $client = new Frontier::Client(url => "http://$satellite/rpc/api");
    my $session = $client->call('auth.login', $user, $password);


    open my $fh, '<', "$channel_cfg" or die $!;
    while( <$fh> ) {
        chomp;   # strip trailing linefeed from $_
        next if /^(\s*(#.*)?)?$/;
	my $channelitem = $_;

        my @channelarray = split('\|',$_);
	
        my $channel_label = $channelarray[0];
	my $channel_name = ($channelarray[1])? "$channelarray[1]" : "$channel_label";
	my $channel_desc = ($channelarray[2])? "$channelarray[2]" : "$channel_name";
	my $channel_arch = ($channelarray[3])? "$channelarray[3]" : "x86_64";
	my $parent_channel = $channelarray[4];
	my $channel_crypto = ($channelarray[5])? "$channelarray[5]" : "sha1";
	my $repo_list = $channelarray[6];

	
	my $gpg_file = ($channelarray[7])? "$channelarray[7]" : "";
	my $channel_schedule = ($channelarray[8])? "$channelarray[8]" : "d";

	my $cron_string = '0 0 3 ? * *';

	if ($channel_schedule eq "w") { $cron_string = '0 0 1 ? * 7'; }
	elsif ($channel_schedule eq "m") { $cron_string = '0 0 3 1 * ?'; }
	elsif ($channel_schedule eq "n") { $cron_string = ''; }

	my $gpg_url = '';
	my $gpg_key = '';
	my $gpg_chksum = '';


	if ( $gpg_file eq "" ) {

		$gpg_url = '';
		$gpg_key = '';
		$gpg_chksum = '';

	}
	else {
		$gpg_chksum = `/usr/bin/gpg --with-fingerprint ${gpg_path}${gpg_file} | grep "fingerprint" | cut -d"=" -f2 2>/dev/null`;
		$gpg_chksum =~ s/^\s+|\s+$//g;

		$gpg_key = `/usr/bin/gpg --with-fingerprint ${gpg_path}${gpg_file} | grep "^pub" | awk '{print \$2}' | cut -d"\/" -f2 2>/dev/null`;
		$gpg_key =~ s/^\s+|\s+$//g;

		$gpg_url = ($gpg_key ne "")? "${gpg_link}${gpg_file}" : "";
	}


	print "Creating channel: $channel_label ...\n";

	eval {   $client->call('channel.software.create',
                 $session,
                 "$channel_label",
                 "$channel_name",
                 "$channel_desc",
                 "channel-$channel_arch",
                 "$parent_channel",
                 $channel_crypto,
                 {
                         'url' => "$gpg_url",
                         'id' => "$gpg_key",
                         'fingerprint' => "$gpg_chksum",
                 },
        );
	};
	print "Warning: channel might be already created with the same label: $channel_label..$@.\n" if $@;




        eval {   $client->call('channel.access.disableUserRestrictions',
                 $session,
                 "$channel_label",
        );
	};
	print "Warning: cannot remove user restrictions for channel: $channel_label...\n" if $@;

        eval {   $client->call('channel.access.setOrgSharing',
                 $session,
                 "$channel_label",
		 'public',
        );
        };
        print "Warning: cannot share the channel: $channel_label...\n" if $@;

# assigning repositories to the channels
	my @repos = split('\,',$repo_list);
	while (@repos) {
		my $repo = shift(@repos);
		print "\t--> Adding repository: $repo...\n";
		eval {
			$client->call('channel.software.associateRepo',
                	$session,
                	"$channel_label",
                	"$repo",
        		);
		};
		print "Warning: cannot add repository: $repo \n" if $@;

		print "\t\t Set the scheduling: $repo...\n";
		eval {
			$client->call('channel.software.syncRepo',
				$session,
				"$channel_label",
				"$cron_string",
			)
		};
		print "Warning: cannot schedule the sync for repository: $repo \n" if $@;

	}

    }

    close $fh;



$client->call('auth.logout', $session);

