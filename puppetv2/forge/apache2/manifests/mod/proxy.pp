class apache2::mod::proxy (
  $proxy_requests = 'Off',
  $allow_from     = undef,
  $apache_version = undef,
  $package_name   = undef,
) {
  include ::apache2
  $_apache_version = pick($apache_version, $apache2::apache_version)
  ::apache2::mod { 'proxy':
    package => $package_name,
  }
  # Template uses $proxy_requests, $_apache_version
  file { 'proxy.conf':
    ensure  => file,
    path    => "${::apache2::mod_dir}/proxy.conf",
    mode    => $::apache2::file_mode,
    content => template('apache2/mod/proxy.conf.erb'),
    require => Exec["mkdir ${::apache2::mod_dir}"],
    before  => File[$::apache2::mod_dir],
    notify  => Class['apache2::service'],
  }
}
