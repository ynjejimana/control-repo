class apache2::mod::peruser (
  $minspareprocessors = '2',
  $minprocessors = '2',
  $maxprocessors = '10',
  $maxclients = '150',
  $maxrequestsperchild = '1000',
  $idletimeout = '120',
  $expiretimeout = '120',
  $keepalive = 'Off',
) {

  case $::osfamily {
    'freebsd' : {
      fail("Unsupported osfamily ${::osfamily}")
    }
    default: {
      if $::osfamily == 'gentoo' {
        ::portage::makeconf { 'apache2_mpms':
          content => 'peruser',
        }
      }

      if defined(Class['apache2::mod::event']) {
        fail('May not include both apache2::mod::peruser and apache2::mod::event on the same node')
      }
      if defined(Class['apache2::mod::itk']) {
        fail('May not include both apache2::mod::peruser and apache2::mod::itk on the same node')
      }
      if defined(Class['apache2::mod::prefork']) {
        fail('May not include both apache2::mod::peruser and apache2::mod::prefork on the same node')
      }
      if defined(Class['apache2::mod::worker']) {
        fail('May not include both apache2::mod::peruser and apache2::mod::worker on the same node')
      }
      File {
        owner => 'root',
        group => $::apache2::params::root_group,
        mode  => $::apache2::file_mode,
      }

      $mod_dir = $::apache2::mod_dir

      # Template uses:
      # - $minspareprocessors
      # - $minprocessors
      # - $maxprocessors
      # - $maxclients
      # - $maxrequestsperchild
      # - $idletimeout
      # - $expiretimeout
      # - $keepalive
      # - $mod_dir
      file { "${::apache2::mod_dir}/peruser.conf":
        ensure  => file,
        mode    => $::apache2::file_mode,
        content => template('apache2/mod/peruser.conf.erb'),
        require => Exec["mkdir ${::apache2::mod_dir}"],
        before  => File[$::apache2::mod_dir],
        notify  => Class['apache2::service'],
      }
      file { "${::apache2::mod_dir}/peruser":
        ensure  => directory,
        require => File[$::apache2::mod_dir],
      }
      file { "${::apache2::mod_dir}/peruser/multiplexers":
        ensure  => directory,
        require => File["${::apache2::mod_dir}/peruser"],
      }
      file { "${::apache2::mod_dir}/peruser/processors":
        ensure  => directory,
        require => File["${::apache2::mod_dir}/peruser"],
      }

      ::apache2::peruser::multiplexer { '01-default': }
    }
  }
}
