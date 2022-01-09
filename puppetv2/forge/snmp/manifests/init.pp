class snmp ($snmp_version = 3, $community_name = undef, $community_password = undef, $config_template = undef) inherits snmp::params {
	package {$snmp::params::package_name:
		ensure => installed,
	}

	service {$snmp::params::service_name:
		ensure    => running,
		enable    => true,
		hasstatus => true,
		require   => Package[$snmp::params::package_name],
	}

	if $config_template != undef {
		file { $snmp::params::config_file_name:
			content => template($config_template),
		}
	}
}
	
