class squid (
    $allowed_networks,
    $http_port,
    $ssl_ports,
    $safe_ports,
    $config_template = undef,
    $allowed_sites_content = undef,
    $allowed_sites_source = undef,
    $allow_all = false,
    $allow_ftp = false,
    $define_cacheobject = true,
    $cache_peer_options = undef,
    $never_direct_all = false,
    $log_to_file = true,
    $log_to_syslog = false,
    $dns_nameservers = undef,
    ) inherits squid::params {

  package { $squid::params::package_name:
    ensure  => installed,
  }

  service { $squid::params::service_name:
    enable     => true,
    ensure     => running,
    hasrestart => true,
    hasstatus  => true,
  }

  File {
    owner => $squid::params::service_user,
    group => $squid::params::service_group,
  }

  file { $squid::params::config_file :
    ensure  => file,
    content => $config_template ? {
      undef   => undef,
      default => template($config_template),
    },
    owner   => root,
    require => Package[$squid::params::package_name],
    notify  => Service[$squid::params::service_name],
  }

  file { "/etc/squid/allowed.sites.conf" :
    ensure  => file,
    content => $allowed_sites_content,
    source  => $allowed_sites_source,
    owner   => root,
    require => File[$squid::params::config_file],
    notify  => Service[$squid::params::service_name],
  }
}
