class apache2::mod::version(
  $apache_version = $::apache2::apache_version
) {

  if ($::osfamily == 'debian' and versioncmp($apache_version, '2.4') >= 0) {
    warning("${module_name}: module version_module is built-in and can't be loaded")
  } else {
    ::apache2::mod { 'version': }
  }
}
