class apache2::mod::fcgid(
  $options = {},
) {
  include ::apache2
  if ($::osfamily == 'RedHat' and $::operatingsystemmajrelease == '7') or $::osfamily == 'FreeBSD' {
    $loadfile_name = 'unixd_fcgid.load'
    $conf_name = 'unixd_fcgid.conf'
  } else {
    $loadfile_name = undef
    $conf_name = 'fcgid.conf'
  }

  ::apache2::mod { 'fcgid':
    loadfile_name => $loadfile_name,
  }

  # Template uses:
  # - $options
  file { $conf_name:
    ensure  => file,
    path    => "${::apache2::mod_dir}/${conf_name}",
    mode    => $::apache2::file_mode,
    content => template('apache2/mod/fcgid.conf.erb'),
    require => Exec["mkdir ${::apache2::mod_dir}"],
    before  => File[$::apache2::mod_dir],
    notify  => Class['apache2::service'],
  }
}
