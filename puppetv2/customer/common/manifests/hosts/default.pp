class common::hosts::default ($hosts) {
	tag "autoupdate"

	if !defined (Host[$::fqdn]) {
		host { $::fqdn:
			ensure       => present,
			ip           => $::ipaddress,
			host_aliases => [ $::hostname ],
		}
	}


  # Removed as this is causing duplicate localhost entry. By default /etc/hosts already got the same 
  #	if !defined ( Host["localhost.localdomain"]) {
  #  host { "localhost.localdomain":
  #		ensure       => present,
  #		ip           => "127.0.0.1",
  #		host_aliases => [ "localhost" ],
  #	}
  #}

	$host_defaults = {
		ensure => present,
	}

	create_resources(host, $hosts, $host_defaults)
}
