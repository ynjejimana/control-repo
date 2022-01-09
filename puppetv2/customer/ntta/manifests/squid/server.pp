class ntta::squid::server ($ssl_ports, $safe_ports, $allowed_networks, $http_port) {
	class {"squid":
		config_template      => "ntta/squid/squid.conf.erb",
		allowed_sites_source => "puppet:///modules/ntta/squid/allowed.sites.conf",
		ssl_ports            => $ssl_ports,
		safe_ports           => $safe_ports,
		allowed_networks     => $allowed_networks,
		http_port            => $http_port,
	}
}