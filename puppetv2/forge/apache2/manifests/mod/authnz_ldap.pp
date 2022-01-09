class apache2::mod::authnz_ldap (
  $verify_server_cert = true,
  $verifyServerCert   = undef,
  $package_name       = undef,
) {
  include ::apache2
  include '::apache2::mod::ldap'
  ::apache2::mod { 'authnz_ldap':
    package => $package_name,
  }

  if $verifyServerCert {
    warning('Class[\'apache2::mod::authnz_ldap\'] parameter verifyServerCert is deprecated in favor of verify_server_cert')
    $_verify_server_cert = $verifyServerCert
  } else {
    $_verify_server_cert = $verify_server_cert
  }

  validate_bool($_verify_server_cert)

  # Template uses:
  # - $_verify_server_cert
  file { 'authnz_ldap.conf':
    ensure  => file,
    path    => "${::apache2::mod_dir}/authnz_ldap.conf",
    mode    => $::apache2::file_mode,
    content => template('apache2/mod/authnz_ldap.conf.erb'),
    require => Exec["mkdir ${::apache2::mod_dir}"],
    before  => File[$::apache2::mod_dir],
    notify  => Class['apache2::service'],
  }
}
