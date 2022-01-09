class apache2::mod::cluster (
  $allowed_network,
  $balancer_name,
  $ip,
  $version,
  $enable_mcpm_receive = true,
  $port = '6666',
  $keep_alive_timeout = 60,
  $manager_allowed_network = '127.0.0.1',
  $max_keep_alive_requests = 0,
  $server_advertise = true,
) {

  include ::apache2

  ::apache2::mod { 'proxy': }
  ::apache2::mod { 'proxy_ajp': }
  ::apache2::mod { 'manager': }
  ::apache2::mod { 'proxy_cluster': }
  ::apache2::mod { 'advertise': }

  if (versioncmp($version, '1.3.0') >= 0 ) {
    ::apache2::mod { 'cluster_slotmem': }
  } else {
    ::apache2::mod { 'slotmem': }
  }

  file {'cluster.conf':
    ensure  => file,
    path    => "${::apache2::mod_dir}/cluster.conf",
    mode    => $::apache2::file_mode,
    content => template('apache2/mod/cluster.conf.erb'),
    require => Exec["mkdir ${::apache2::mod_dir}"],
    before  => File[$::apache2::mod_dir],
    notify  => Class['apache2::service'],
  }

}
