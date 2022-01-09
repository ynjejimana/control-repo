class common::iptables::disable {
  tag "autoupdate"

  $ipv4_service_name = $::osfamily ? {
    "redhat" => "iptables",
    "debian" => "ufw",
    default => "iptables",
  }

  $ipv6_service_name = $::osfamily ? {
    "redhat" => "ip6tables",
    default => "ip6tables",
  }

  if $ipv4_service_name != undef {
    if ! defined(Service[$ipv4_service_name]) {
      service { $ipv4_service_name :
        enable => false,
        ensure => stopped,
      }
    }
  }

  if $ipv6_service_name != undef {
    if ! defined(Service[$ipv6_service_name]) {
      service { $ipv6_service_name :
        enable => false,
        ensure => stopped,
      }
    }
  }
}
