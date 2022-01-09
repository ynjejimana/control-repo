class apache2 (
  $default_vhost = false,
  $default_ssl_vhost = false,
  $install_ssl_module = false,
  $install_passenger_module = false,
  $passenger_root = undef,
  $passenger_ruby = '/usr/bin/ruby',
  $passenger_manage_repo = false,
  $apache_vhosts = undef,
) {
  class { ::apache2:
    default_vhost     => $default_vhost,
    default_ssl_vhost => $default_ssl_vhost,
  }

  if install_ssl_module {
    class { ::apache2::mod::ssl: }
  }

  if install_passenger_module {
    class { ::apache2::mod::passenger:
      passenger_root => $passenger_root,
      passenger_ruby => $passenger_ruby,
      manage_repo    => $passenger_manage_repo,
    }
  }

  if defined($apache_vhosts) {
    create_resources(::apache2::vhost, $apache_vhosts)
  }
}
