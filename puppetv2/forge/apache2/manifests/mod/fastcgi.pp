class apache2::mod::fastcgi {
  include ::apache2

  # Debian specifies it's fastcgi lib path, but RedHat uses the default value
  # with no config file
  $fastcgi_lib_path = $::apache2::params::fastcgi_lib_path

  ::apache2::mod { 'fastcgi': }

  if $fastcgi_lib_path {
    # Template uses:
    # - $fastcgi_server
    # - $fastcgi_socket
    # - $fastcgi_dir
    file { 'fastcgi.conf':
      ensure  => file,
      path    => "${::apache2::mod_dir}/fastcgi.conf",
      mode    => $::apache2::file_mode,
      content => template('apache2/mod/fastcgi.conf.erb'),
      require => Exec["mkdir ${::apache2::mod_dir}"],
      before  => File[$::apache2::mod_dir],
      notify  => Class['apache2::service'],
    }
  }

}
