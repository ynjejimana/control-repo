class common::ssh::server (
	$ssh_as_root = "yes",
	$allow_tcp_forwarding = "yes",
	$client_alive_interval = 1200,
	$client_alive_count_max = 0,
	$listenAddresses = [$::ipaddress],
	$login_grace_time = 60,
	$x11_forwarding = "no",
	$kex_algorithms = undef,
	$ciphers = undef,
	$macs = undef,
	$banner_file = undef,
	$sftp_subsystem = "/usr/libexec/openssh/sftp-server",
	$sshd_config_match = undef,
	) {
	# tag "autoupdate"

	$package_name = $::osfamily ? {
		"redhat" => ["openssh-server", "openssh-clients"],
		"debian" => ["openssh-server", "openssh-client"],
		default => ["openssh"],
	}
	
	$service_name = $::osfamily ? {
		"redhat" => "sshd",
		"debian" => "ssh",
		default => "sshd",
	}

	package { $package_name :
		ensure => installed,
	}

	service { $service_name :
		ensure     => running,
		hasrestart => true,
		hasstatus  => true,
		enable     => true,
	}

	exec { "/sbin/service sshd restart":
		subscribe   =>	File["/etc/ssh/sshd_config"],
		refreshonly	=>	true,
	}

	file { "/etc/ssh/sshd_config":
		ensure  =>	present,
		owner   =>	'root',
		group   =>	'root',
		mode    =>	'0600',
		content	=>	template("common/ssh/sshd_config.erb"),
	}
}
