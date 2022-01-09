class apache2::mod::cgid {
  case $::osfamily {
    'FreeBSD': {}
    default: {
      if defined(Class['::apache2::mod::event']) {
        Class['::apache2::mod::event'] -> Class['::apache2::mod::cgid']
      } else {
        Class['::apache2::mod::worker'] -> Class['::apache2::mod::cgid']
      }
    }
  }

  # Debian specifies it's cgid sock path, but RedHat uses the default value
  # with no config file
  $cgisock_path = $::osfamily ? {
    'debian'  => "\${APACHE_RUN_DIR}/cgisock",
    'freebsd' => 'cgisock',
    default   => undef,
  }
  ::apache2::mod { 'cgid': }
  if $cgisock_path {
    # Template uses $cgisock_path
    file { 'cgid.conf':
      ensure  => file,
      path    => "${::apache2::mod_dir}/cgid.conf",
      mode    => $::apache2::file_mode,
      content => template('apache2/mod/cgid.conf.erb'),
      require => Exec["mkdir ${::apache2::mod_dir}"],
      before  => File[$::apache2::mod_dir],
      notify  => Class['apache2::service'],
    }
  }
}
