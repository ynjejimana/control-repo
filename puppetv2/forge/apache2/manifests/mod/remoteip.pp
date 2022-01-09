class apache2::mod::remoteip (
  $header            = 'X-Forwarded-For',
  $proxy_ips         = [ '127.0.0.1' ],
  $proxies_header    = undef,
  $trusted_proxy_ips = undef,
  $apache_version    = undef,
) {
  include ::apache2
  $_apache_version = pick($apache_version, $apache2::apache_version)
  if versioncmp($_apache_version, '2.4') < 0 {
    fail('mod_remoteip is only available in Apache 2.4')
  }

  ::apache2::mod { 'remoteip': }

  # Template uses:
  # - $header
  # - $proxy_ips
  # - $proxies_header
  # - $trusted_proxy_ips
  file { 'remoteip.conf':
    ensure  => file,
    path    => "${::apache2::mod_dir}/remoteip.conf",
    mode    => $::apache2::file_mode,
    content => template('apache2/mod/remoteip.conf.erb'),
    require => Exec["mkdir ${::apache2::mod_dir}"],
    before  => File[$::apache2::mod_dir],
    notify  => Service['httpd'],
  }
}
