class apache2::dev {

  if ! defined(Class['apache2']) {
    fail('You must include the apache base class before using any apache defined resources')
  }

  $packages = $::apache2::dev_packages
  if $packages { # FreeBSD doesn't have dev packages to install
    package { $packages:
      ensure  => present,
      require => Package['httpd'],
    }
  }
}
