class common::puppet::client ($puppet_server, $version, $dns_alt_names = [], $noclient = true, $update_puppet_cron) {
	# Only run this code if the server is not a puppetmaster
	if !defined("common::puppet::puppetmaster") {
		class { "::puppet::client" :
			puppet_server => $puppet_server,
			noclient      => $noclient,
			version       => $version,
			dns_alt_names => $dns_alt_names,
		}

		class { "::salt::minion":
			salt_master => $puppet_server,
		}

		Cron {
			month => "*",
			monthday => "*",
			user => "root",
			minute => fqdn_rand( 60 ),
		}

		$ensure_update_puppet_cron = $update_puppet_cron ? {
			true => "present",
			false => "absent"
		}

		cron { "update-puppet":
			command => "/usr/bin/puppet agent --test --tags common::puppet::client,common::puppet::cron --logdest syslog > /dev/null 2>&1",
			hour    => "*/2",
			ensure  => $ensure_update_puppet_cron,
		}
	}
}
