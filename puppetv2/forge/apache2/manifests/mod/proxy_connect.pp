class apache2::mod::proxy_connect (
  $apache_version  = undef,
) {
  include ::apache2
  $_apache_version = pick($apache_version, $apache2::apache_version)
  if versioncmp($_apache_version, '2.2') >= 0 {
    Class['::apache2::mod::proxy'] -> Class['::apache2::mod::proxy_connect']
    ::apache2::mod { 'proxy_connect': }
  }
}
