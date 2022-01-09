class apache2::mod::wsgi (
  $wsgi_socket_prefix = $::apache2::params::wsgi_socket_prefix,
  $wsgi_python_path   = undef,
  $wsgi_python_home   = undef,
  $package_name       = undef,
  $mod_path           = undef,
) inherits ::apache2::params {
  include ::apache2
  if ($package_name != undef and $mod_path == undef) or ($package_name == undef and $mod_path != undef) {
    fail('apache2::mod::wsgi - both package_name and mod_path must be specified!')
  }

  if $package_name != undef {
    if $mod_path =~ /\// {
      $_mod_path = $mod_path
    } else {
      $_mod_path = "${::apache2::lib_path}/${mod_path}"
    }
    ::apache2::mod { 'wsgi':
      package => $package_name,
      path    => $_mod_path,
    }
  }
  else {
    ::apache2::mod { 'wsgi': }
  }

  # Template uses:
  # - $wsgi_socket_prefix
  # - $wsgi_python_path
  # - $wsgi_python_home
  file {'wsgi.conf':
    ensure  => file,
    path    => "${::apache2::mod_dir}/wsgi.conf",
    mode    => $::apache2::file_mode,
    content => template('apache2/mod/wsgi.conf.erb'),
    require => Exec["mkdir ${::apache2::mod_dir}"],
    before  => File[$::apache2::mod_dir],
    notify  => Class['apache2::service'],
  }
}

