define squid::config ($value, $ensure = present) {

  Augeas {
    incl    => $squid::params::config_file,
    lens    => 'Squid.lns',
    notify  => Service[$squid::params::service_name],
    require => File[$squid::params::config_file],
  }

  case $ensure {
    present: {
      augeas { "set squid '${name}' to '${value}'":
        changes => "set ${name} '${value}'",
      }
    }
    absent: {
      augeas { "rm squid '${name}'":
        changes => "rm ${name}",
      }
    }
    default: {}
  }
}