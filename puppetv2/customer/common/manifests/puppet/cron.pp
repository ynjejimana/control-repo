class common::puppet::cron ($noop_cron, $autoupdate_cron) {
	Cron {
		month => "*",
		monthday => "*",
		user => "root",
		minute => fqdn_rand( 60 ),
	}

	$ensure_autoupdate_cron = $autoupdate_cron ? {
		true => "present",
		false => "absent"
	}

	cron { "puppet-autoupdate":
		command => "/usr/bin/puppet agent --test --tags autoupdate --logdest syslog > /dev/null 2>&1",
		hour    => [9,11,13,15],
		weekday => [1,2,3,4],
		ensure  => $ensure_autoupdate_cron,
	}

	$ensure_noop_cron = $noop_cron ? {
		true => "present",
		false => "absent"
	}

	# Runs puppet with the --noop option so that Foreman can see whether a host has problems or not
	cron { "puppet-noop":
		command => "/usr/bin/puppet agent --test --noop --logdest syslog > /dev/null 2>&1",
		hour    => 1,
		ensure  => $ensure_noop_cron,
	}
}
