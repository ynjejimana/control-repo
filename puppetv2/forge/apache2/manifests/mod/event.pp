class apache2::mod::event (
  $startservers           = '2',
  $maxclients             = '150',
  $maxrequestworkers      = undef,
  $minsparethreads        = '25',
  $maxsparethreads        = '75',
  $threadsperchild        = '25',
  $maxrequestsperchild    = '0',
  $maxconnectionsperchild = undef,
  $serverlimit            = '25',
  $apache_version         = $::apache2::apache_version,
  $threadlimit            = '64',
  $listenbacklog          = '511',
) {
  if defined(Class['apache2::mod::itk']) {
    fail('May not include both apache2::mod::event and apache2::mod::itk on the same node')
  }
  if defined(Class['apache2::mod::peruser']) {
    fail('May not include both apache2::mod::event and apache2::mod::peruser on the same node')
  }
  if defined(Class['apache2::mod::prefork']) {
    fail('May not include both apache2::mod::event and apache2::mod::prefork on the same node')
  }
  if defined(Class['apache2::mod::worker']) {
    fail('May not include both apache2::mod::event and apache2::mod::worker on the same node')
  }
  File {
    owner => 'root',
    group => $::apache2::params::root_group,
    mode  => $::apache2::file_mode,
  }

  # Template uses:
  # - $startservers
  # - $maxclients
  # - $minsparethreads
  # - $maxsparethreads
  # - $threadsperchild
  # - $maxrequestsperchild
  # - $serverlimit
  file { "${::apache2::mod_dir}/event.conf":
    ensure  => file,
    mode    => $::apache2::file_mode,
    content => template('apache2/mod/event.conf.erb'),
    require => Exec["mkdir ${::apache2::mod_dir}"],
    before  => File[$::apache2::mod_dir],
    notify  => Class['apache2::service'],
  }

  case $::osfamily {
    'redhat': {
      if versioncmp($apache_version, '2.4') >= 0 {
        apache2::mpm{ 'event':
          apache_version => $apache_version,
        }
      }
    }
    'debian','freebsd' : {
      apache2::mpm{ 'event':
        apache_version => $apache_version,
      }
    }
    'gentoo': {
      ::portage::makeconf { 'apache2_mpms':
        content => 'event',
      }
    }
    default: {
      fail("Unsupported osfamily ${::osfamily}")
    }
  }
}
