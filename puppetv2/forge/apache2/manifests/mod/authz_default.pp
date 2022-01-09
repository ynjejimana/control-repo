class apache2::mod::authz_default(
    $apache_version = $::apache2::apache_version
) {
  if versioncmp($apache_version, '2.4') >= 0 {
    warning('apache2::mod::authz_default has been removed in Apache 2.4')
  } else {
    ::apache2::mod { 'authz_default': }
  }
}
