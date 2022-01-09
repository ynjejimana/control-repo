class apache2::mod::dav_svn (
  $authz_svn_enabled = false,
) {
  Class['::apache2::mod::dav'] -> Class['::apache2::mod::dav_svn']
  include ::apache2
  include ::apache2::mod::dav
  ::apache2::mod { 'dav_svn': }

  if $::osfamily == 'Debian' and ($::operatingsystemmajrelease != '6' and $::operatingsystemmajrelease != '10.04' and $::operatingsystemrelease != '10.04') {
    $loadfile_name = undef
  } else {
    $loadfile_name = 'dav_svn_authz_svn.load'
  }

  if $authz_svn_enabled {
    ::apache2::mod { 'authz_svn':
      loadfile_name => $loadfile_name,
      require       => Apache2::Mod['dav_svn'],
    }
  }
}
