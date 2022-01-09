class common::iptables::enable {
  tag 'autoupdate'

  $ipv4_service_name = $::osfamily ? {
    'redhat' => 'iptables',
    'debian' => 'ufw',
    default => 'iptables',
  }

  $ipv6_service_name = $::osfamily ? {
    "redhat" => "ip6tables",
    default => "ip6tables",
  }

  if $ipv4_service_name != undef {
    if ! defined(Service[$ipv4_service_name]) {
      service { $ipv4_service_name :
        ensure => running,
        enable => true,
      }
    }
    if $soe::linux::iptables_rules != undef {
     file { '/etc/sysconfig/iptables':
       ensure  => present,
       owner   => 'root',
       mode    => '0600',
       source => "puppet:///modules/common/iptables/${soe::linux::iptables_rules}",
       notify   => Service["${ipv4_service_name}"],
     }
    }
  } else {
  	notify {"Failed to determine iptables service name, skipping...":}
  }

  if $ipv6_service_name != undef {
    if ! defined(Service[$ipv6_service_name]) {
      service { $ipv6_service_name :
        ensure => running,
        enable => true,
      }
    }
  }
}
