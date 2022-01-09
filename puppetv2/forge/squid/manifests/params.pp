class squid::params {
	$package_name = $::osfamily ? {
		"RedHat" => "squid",
		default => "squid",
	}

	$service_name = $::osfamily ? {
		"RedHat" => "squid",
		default => "squid",
	}

	$config_dir = $::osfamily ? {
		"RedHat" => "/etc/squid",
		default => "/etc/squid",
	}

	$config_file = "${config_dir}/squid.conf"

	$service_user = $::osfamily ? {
		"RedHat" => "squid",
		default => "squid",
	}

	$service_group = $::osfamily ? {
		"RedHat" => "squid",
		default => "squid",
	}

	$log_dir = $::osfamily ? {
		"RedHat" => "/var/log/squid",
		default => "/var/log/squid",
	}

	$spool_dir = $::osfamily ? {
		"RedHat" => "/var/spool/squid",
		default => "/var/spool/squid",
	}
}