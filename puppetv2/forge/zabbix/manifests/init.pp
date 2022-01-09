class zabbix (
	$agent_package_name = $zabbix::params::agent_package_name,
	$agentd_conf = $zabbix::params::agentd_conf,
	$user_home_dir = $zabbix::params::user_home_dir,
)
inherits zabbix::params {

  
  File {
    owner => zabbix,
    group => zabbix,
    mode => 0755,
    require => Package[$agent_package_name],
  }

  file {
    $config_dir:
      owner   => root,
      group   => root,
      ensure => directory;
    $log_dir:
      ensure => directory;
    $pid_dir:
      ensure => directory;
    $user_home_dir:
      ensure => directory,
      mode  => '0700',
      require => User[$user];
  }

  user { $user :
    ensure     => 'present',
    home       => $user_home_dir,
    password   => '!!',
    shell      => '/bin/bash',
    gid        => $group,
    managehome => true,
    require    => Package[$agent_package_name],
  }

  group { $group:
    ensure  => 'present',
    require => Package[$agent_package_name],
  }
}
