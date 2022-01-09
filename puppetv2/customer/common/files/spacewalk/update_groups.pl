#!/usr/bin/perl -w

    use strict;
    use Frontier::Client;
    use Data::Dumper;
    use warnings;
    use Cwd;
    use File::Find;


    my $search_dir = '/root/git/hiera';
    my $file_pattern = 'yaml';
    my $search_pattern = 'spacewalk::client::activation_key';

    my $satellite = 'localhost';

    if ( $#ARGV != 1 ) {
        print "ERROR - Usage: update_groups.pl username password \n";
        exit;
    }

    my $user = "$ARGV[0]";
    my $password = "$ARGV[1]";

    my $sw_client = new Frontier::Client(url => "http://$satellite/rpc/api");
    my $session = $sw_client->call('auth.login', $user, $password);

    find( \&d, $search_dir );

    sub d {


	my $file = $File::Find::name;

  	return unless -f $file;
  	return unless $file =~ /$file_pattern/;

  	open F, $file or print "couldn't open $file\n" && return;

     	while (<F>) {
		if (my ($found) = m/($search_pattern)/o) {
			my @act_key_temp = split('\:\ ',$_);
			$act_key_temp[1] =~ s/"//g;
			my $group_name = $act_key_temp[1];
			my $key_label = $act_key_temp[1];

			my $empty = "";
			my @perm = [ "" ];
			my $default_key;
			my $grp;

        		print "Procesing group/activation key for $group_name\n";
           		print "--- Creating system group: $group_name\n";
           		eval { $grp = $sw_client->call('systemgroup.create',
				$session,
				$group_name,
				$group_name,
				);
			};
			if ( $@ ) {
				print "------ Warning: group with such name is already exist : $group_name\n";
			}
			else {

			my @grp_id = [ "$grp->{'id'}" ];

			print "--- Creating activation key: $group_name\n";
			eval { $sw_client->call('activationkey.create',
				$session,
				$key_label,
				$key_label,
				$empty,
				@perm,
				$sw_client->boolean(0),
				);
			};
			print "------ Warning:iactivation key with such label is alredy exist : $key_label ... ($@)\n" if $@;

			print "--- Linking group to activation key: $group_name\n";
			eval { $sw_client->call('activationkey.addServerGroups',
				$session,
				"1-$key_label",
				@grp_id,
				);
			};
			print "------ Warning: ($@) cannot link the group to the key... \n" if $@;

			}
         	}
	}

        close F;
   }
   $sw_client->call('auth.logout', $session);
