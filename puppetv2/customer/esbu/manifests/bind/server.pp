# Class that creates a slave DNS server that feeds off Infoblox
class esbu::bind::server (
  $listen_on_addr = [ "${::ipaddress_lo}", "${::ipaddress}" ],
  $listen_on_v6_addr = [ "${::ipaddress_lo}", "${::ipaddress}" ],
  $listen_on_v6_port = false,
  $forwarders = {},
  $tsig_keys = {},
  $acls = {},
  $zones = {},
  $views = {},
  $includes = [],
  $recursion = 'no',
  $allow_recursion = [],
  $also_notify = [],
  $send_notifies = '',
  $chroot = false,
  $masters = {},
  $allow_query = [ 'any' ],
  $check_names = [],
  $allow_transfer = [],
  $main_log_to_file = true,
  $main_log_versions = 3,
  $main_log_size = '5m',
  $main_log_to_syslog = false,
  $query_log_to_file = false,
  $query_log_versions = 5,
  $query_log_size = '500m',
  $query_log_to_syslog = false,
  $query_log_syslog_facility = 'daemon',
) {

  class { '::bind':
    chroot => $chroot,
  }

  bind::server::conf { '/etc/named.conf':
    listen_on_addr      => $listen_on_addr,
    listen_on_v6_addr   => $listen_on_v6_addr,
    listen_on_v6_port   => $listen_on_v6_port,
    forwarders          => $forwarders,
    allow_query         => $allow_query,
    also_notify         => $also_notify,
    send_notifies       => $send_notifies,
    zones               => $zones,
    views               => $views,
    includes            => $includes,
    acls                => $acls,
    tsig_keys           => $tsig_keys,
    recursion           => $recursion,
    allow_recursion     => $allow_recursion,
    masters             => $masters,
    dnssec_enable       => 'no',
    dnssec_validation   => 'no',
    check_names         => $check_names,
    allow_transfer      => $allow_transfer,
    main_log_to_file    => $main_log_to_file,
    main_log_versions   => $main_log_versions,
    main_log_size       => $main_log_size,
    main_log_to_syslog  => $main_log_to_syslog,
    query_log_to_file   => $query_log_to_file,
    query_log_versions  => $query_log_versions,
    query_log_size      => $query_log_size,
    query_log_to_syslog => $query_log_to_syslog,
    query_log_syslog_facility => $query_log_syslog_facility,
  }

  File {
    owner => 'named',
    group => 'named',
    mode => '0640',
    ensure => file,
    require => Class['::bind'],
  }

  # Setting standard zone file contents
  file { '/etc/named.rfc1912.zones':
    source => 'puppet:///modules/esbu/bind/named.rfc1912.zones',
  }

  file { '/var/named/named.empty':
    source => 'puppet:///modules/esbu/bind/named.empty',
  }
}
