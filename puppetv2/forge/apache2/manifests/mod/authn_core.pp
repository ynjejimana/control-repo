class apache2::mod::authn_core(
  $apache_version = $::apache2::apache_version
) {
  if versioncmp($apache_version, '2.4') >= 0 {
    ::apache2::mod { 'authn_core': }
  }
}
