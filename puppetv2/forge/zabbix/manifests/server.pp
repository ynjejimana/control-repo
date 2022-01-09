class zabbix::server inherits zabbix {

  File {
    group => "zabbix",
    owner => "zabbix",
    mode => "0644",
    replace => true,
  }

  # packages
  package { "fping":
    ensure  => installed,
  }

  package { "iksemel":
    ensure  => installed,
  }

  package { "zabbix-server-mysql":
    ensure  => installed,
    require => [ Package["fping"], Package["iksemel"] ],
  }

  package { $server_package_name:
    ensure  => installed,
    require => [ Package["zabbix-server-mysql"] ],
  }

  # services
  service { $server_service_name:
    ensure    => running,
    enable    => true,
    require   => Package[$server_package_name],
    subscribe => File["${config_dir}/zabbix_server.conf"],
  }

  # files
  file { "${config_dir}/zabbix_server.conf" :
		ensure    => file,
    content => template("zabbix/zabbix_server_conf.erb"),
    backup  => false,
    require => Package[$server_package_name],
  }
}
