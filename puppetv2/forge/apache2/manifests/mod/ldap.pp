class apache2::mod::ldap (
  $apache_version                = undef,
  $package_name                  = undef,
  $ldap_trusted_global_cert_file = undef,
  $ldap_trusted_global_cert_type = 'CA_BASE64',
  $ldap_shared_cache_size        = undef,
  $ldap_cache_entries            = undef,
  $ldap_cache_ttl                = undef,
  $ldap_opcache_entries          = undef,
  $ldap_opcache_ttl              = undef,
){
  include ::apache2
  $_apache_version = pick($apache_version, $apache2::apache_version)
  if ($ldap_trusted_global_cert_file) {
    validate_string($ldap_trusted_global_cert_type)
  }
  ::apache22::mod { 'ldap':
    package => $package_name,
  }
  # Template uses $_apache_version
  file { 'ldap.conf':
    ensure  => file,
    path    => "${::apache22::mod_dir}/ldap.conf",
    mode    => $::apache22::file_mode,
    content => template('apache2/mod/ldap.conf.erb'),
    require => Exec["mkdir ${::apache22::mod_dir}"],
    before  => File[$::apache22::mod_dir],
    notify  => Class['apache2::service'],
  }
}
