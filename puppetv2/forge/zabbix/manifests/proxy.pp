class zabbix::proxy ($zabbix_server = [], $zabbix_proxy_config_frequency = 180, $zabbix_proxy_config_cachesize = '256M') inherits zabbix {
	$proxy_conf = "${config_dir}/zabbix_proxy.conf"
	$sqlitedb_file = "${user_home_dir}/zabbix.sqlite3"

	package {
		"zabbix-proxy-sqlite3":
			ensure => installed;
		$proxy_package_name :
			ensure  => installed,
			require => Package["zabbix-proxy-sqlite3"];
		'fping':
			ensure  => installed,
	}

	if ! defined(Class["sqlite"]) {
		class { "sqlite": }
	}

	sqlite::db { 'zabbix':
		owner    => 'zabbix',
		location => $sqlitedb_file,
		group    => 'zabbix',
	}

	file { $proxy_include_dir :
		owner  => 'root',
		group  => 'root',
		mode   => '0755',
		ensure => directory,
	}

	file { $proxy_conf :
		owner   => 'root',
		group   => $group,
		mode    => '0640',
		content => template("zabbix/zabbix_proxy_conf.erb"),
		notify  => Service[$proxy_service_name],
		require => [ Package[$proxy_package_name] ]
	}

	service { $proxy_service_name :
		enable     => true,
		ensure     => running,
		hasstatus  => true,
		hasrestart => true,
		require    => [ Package[$proxy_package_name], File[$proxy_conf], Sqlite::Db['zabbix'] ],
	}
}
