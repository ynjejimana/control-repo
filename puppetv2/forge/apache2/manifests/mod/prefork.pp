class apache2::mod::prefork (
  $startservers        = '8',
  $minspareservers     = '5',
  $maxspareservers     = '20',
  $serverlimit         = '256',
  $maxclients          = '256',
  $maxrequestsperchild = '4000',
  $apache_version      = $::apache2::apache_version,
) {
  if defined(Class['apache2::mod::event']) {
    fail('May not include both apache2::mod::prefork and apache2::mod::event on the same node')
  }
  if versioncmp($apache_version, '2.4') < 0 {
    if defined(Class['apache2::mod::itk']) {
      fail('May not include both apache2::mod::prefork and apache2::mod::itk on the same node')
    }
  }
  if defined(Class['apache2::mod::peruser']) {
    fail('May not include both apache2::mod::prefork and apache2::mod::peruser on the same node')
  }
  if defined(Class['apache2::mod::worker']) {
    fail('May not include both apache2::mod::prefork and apache2::mod::worker on the same node')
  }
  File {
    owner => 'root',
    group => $::apache2::params::root_group,
    mode  => $::apache2::file_mode,
  }

  # Template uses:
  # - $startservers
  # - $minspareservers
  # - $maxspareservers
  # - $serverlimit
  # - $maxclients
  # - $maxrequestsperchild
  file { "${::apache2::mod_dir}/prefork.conf":
    ensure  => file,
    content => template('apache2/mod/prefork.conf.erb'),
    require => Exec["mkdir ${::apache2::mod_dir}"],
    before  => File[$::apache2::mod_dir],
    notify  => Class['apache2::service'],
  }

  case $::osfamily {
    'redhat': {
      if versioncmp($apache_version, '2.4') >= 0 {
        ::apache2::mpm{ 'prefork':
          apache_version => $apache_version,
        }
      }
      else {
        file_line { '/etc/sysconfig/httpd prefork enable':
          ensure  => present,
          path    => '/etc/sysconfig/httpd',
          line    => '#HTTPD=/usr/sbin/httpd.worker',
          match   => '#?HTTPD=/usr/sbin/httpd.worker',
          require => Package['httpd'],
          notify  => Class['apache2::service'],
        }
      }
    }
    'debian', 'freebsd', 'Suse' : {
      ::apache2::mpm{ 'prefork':
        apache_version => $apache_version,
      }
    }
    'gentoo': {
      ::portage::makeconf { 'apache2_mpms':
        content => 'prefork',
      }
    }
    default: {
      fail("Unsupported osfamily ${::osfamily}")
    }
  }
}
