class common::ipv6::enable {
	tag "autoupdate"
	
	$options = $operatingsystem ? {
		/(RedHat|CentOS|OracleLinux)/ => ["net.ipv6.conf.all.disable_ipv6", "net.ipv6.conf.default.disable_ipv6"],
		'Ubuntu' => ["net.ipv6.conf.all.disable_ipv6", "net.ipv6.conf.default.disable_ipv6", "net.ipv6.conf.lo.disable_ipv6"],
		'Debian' => ["net.ipv6.conf.all.disable_ipv6"],
		default => undef,
	}

	if $options != undef {
		sysctl { $options :
			ensure => present,
			value  => "0",
		}
	}

}
