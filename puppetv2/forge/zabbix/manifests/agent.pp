class zabbix::agent ($zabbix_proxy_servers = [], $enable_remote_commands = 0, $agent_package_name = $zabbix::params::agent_package_name, $agentd_conf = $zabbix::params::agentd_conf, $agent_config_files = [], $agent_include_dir_extra = $zabbix::params::agent_include_dir_extra) inherits zabbix {
  package { [$agent_package_name]:
    ensure  => installed,
  }

  if $::operatingsystem == "RedHat" {
    package { ["zabbix-get", "zabbix-sender"]:
      ensure => installed,
    }
  }

  file {
    $userparameter_config_dir :
      ensure => directory,
      owner => root,
      group => root,
      mode => '0755',
      require => [ Package[$agent_package_name], File[$config_dir] ];

    $agentd_conf :
      ensure => file,
      owner => root,
      group => root,
      mode => '0644',
      content => template("zabbix/zabbix_agentd_conf.erb"),
      notify  => Service[$agent_service_name],
      require => [ Package[$agent_package_name], File[$config_dir] ];
  }

  if $agent_config_files != [] {
    $agent_config_file_defaults = {
      mode => '0644',
      owner => root,
      group => root,
      require => [ Package[$agent_package_name], File[$config_dir] ],
      notify => Service[$agent_service_name],
    }
    create_resources(file, $agent_config_files, $agent_config_file_defaults)
  }

  define include_dir_array( $service_name=undef, $config_dir=undef ) {
    file { $name:
      path   => "${config_dir}/${name}",
      ensure => directory,
      mode   => 0755,
      owner  => 'root',
      group  => 'root',
      notify => Service[$service_name],
    }
  }

  include_dir_array { $agent_include_dir_extra: service_name => $agent_service_name, config_dir => $config_dir }


  service { $agent_service_name :
    enable => true,
    ensure => running,
    hasstatus => true,
    hasrestart => true,
    require => [ Package[$agent_package_name], File[$config_dir], File[$log_dir], File[$pid_dir] ];
  }
}


