class apache2::mod::itk (
  $startservers        = '8',
  $minspareservers     = '5',
  $maxspareservers     = '20',
  $serverlimit         = '256',
  $maxclients          = '256',
  $maxrequestsperchild = '4000',
  $apache_version      = $::apache2::apache_version,
) {
  if defined(Class['apache2::mod::event']) {
    fail('May not include both apache2::mod::itk and apache2::mod::event on the same node')
  }
  if defined(Class['apache2::mod::peruser']) {
    fail('May not include both apache2::mod::itk and apache2::mod::peruser on the same node')
  }
  if versioncmp($apache_version, '2.4') < 0 {
    if defined(Class['apache2::mod::prefork']) {
      fail('May not include both apache2::mod::itk and apache2::mod::prefork on the same node')
    }
  } else {
    # prefork is a requirement for itk in 2.4; except on FreeBSD and Gentoo, which are special
    if $::osfamily =~ /^(FreeBSD|Gentoo)/ {
      if defined(Class['apache2::mod::prefork']) {
        fail('May not include both apache2::mod::itk and apache2::mod::prefork on the same node')
      }
    } else {
      if ! defined(Class['apache2::mod::prefork']) {
        fail('apache2::mod::prefork is a prerequisite for apache2::mod::itk, please arrange for it to be included.')
      }
    }
  }
  if defined(Class['apache2::mod::worker']) {
    fail('May not include both apache2::mod::itk and apache2::mod::worker on the same node')
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
  file { "${::apache2::mod_dir}/itk.conf":
    ensure  => file,
    mode    => $::apache2::file_mode,
    content => template('apache2/mod/itk.conf.erb'),
    require => Exec["mkdir ${::apache2::mod_dir}"],
    before  => File[$::apache2::mod_dir],
    notify  => Class['apache2::service'],
  }

  case $::osfamily {
    'redhat': {
      package { 'httpd-itk':
        ensure => present,
      }
      if versioncmp($apache_version, '2.4') >= 0 {
        ::apache2::mpm{ 'itk':
          apache_version => $apache_version,
        }
      }
      else {
        file_line { '/etc/sysconfig/httpd itk enable':
          ensure  => present,
          path    => '/etc/sysconfig/httpd',
          line    => 'HTTPD=/usr/sbin/httpd.itk',
          match   => '#?HTTPD=/usr/sbin/httpd.itk',
          require => Package['httpd'],
          notify  => Class['apache2::service'],
        }
      }
    }
    'debian', 'freebsd': {
      apache2::mpm{ 'itk':
        apache_version => $apache_version,
      }
    }
    'gentoo': {
      ::portage::makeconf { 'apache2_mpms':
        content => 'itk',
      }
    }
    default: {
      fail("Unsupported osfamily ${::osfamily}")
    }
  }
}
