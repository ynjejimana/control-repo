class apache2::default_mods (
  $all            = true,
  $mods           = undef,
  $apache_version = $::apache2::apache_version,
  $use_systemd    = $::apache2::use_systemd,
) {
  # These are modules required to run the default configuration.
  # They are not configurable at this time, so we just include
  # them to make sure it works.
  case $::osfamily {
    'redhat': {
      ::apache2::mod { 'log_config': }
      if versioncmp($apache_version, '2.4') >= 0 {
        # Lets fork it
        # Do not try to load mod_systemd on RHEL/CentOS 6 SCL.
        if ( !($::osfamily == 'redhat' and versioncmp($::operatingsystemrelease, '7.0') == -1) and !($::operatingsystem == 'Amazon') ) {
          if ($use_systemd) {
            ::apache2::mod { 'systemd': }
          }
        }
        ::apache2::mod { 'unixd': }
      }
    }
    'freebsd': {
      ::apache2::mod { 'log_config': }
      ::apache2::mod { 'unixd': }
    }
    'Suse': {
      ::apache2::mod { 'log_config': }
    }
    default: {}
  }
  case $::osfamily {
    'gentoo': {}
    default: {
      ::apache2::mod { 'authz_host': }
    }
  }
  # The rest of the modules only get loaded if we want all modules enabled
  if $all {
    case $::osfamily {
      'debian': {
        include ::apache2::mod::authn_core
        include ::apache2::mod::reqtimeout
        if versioncmp($apache_version, '2.4') < 0 {
          ::apache2::mod { 'authn_alias': }
        }
      }
      'redhat': {
        include ::apache2::mod::actions
        include ::apache2::mod::authn_core
        include ::apache2::mod::cache
        include ::apache2::mod::ext_filter
        include ::apache2::mod::mime
        include ::apache2::mod::mime_magic
        include ::apache2::mod::rewrite
        include ::apache2::mod::speling
        include ::apache2::mod::suexec
        include ::apache2::mod::version
        include ::apache2::mod::vhost_alias
        ::apache2::mod { 'auth_digest': }
        ::apache2::mod { 'authn_anon': }
        ::apache2::mod { 'authn_dbm': }
        ::apache2::mod { 'authz_dbm': }
        ::apache2::mod { 'authz_owner': }
        ::apache2::mod { 'expires': }
        ::apache2::mod { 'include': }
        ::apache2::mod { 'logio': }
        ::apache2::mod { 'substitute': }
        ::apache2::mod { 'usertrack': }

        if versioncmp($apache_version, '2.4') < 0 {
          ::apache2::mod { 'authn_alias': }
          ::apache2::mod { 'authn_default': }
        }
      }
      'freebsd': {
        include ::apache2::mod::actions
        include ::apache2::mod::authn_core
        include ::apache2::mod::cache
        include ::apache2::mod::disk_cache
        include ::apache2::mod::headers
        include ::apache2::mod::info
        include ::apache2::mod::mime_magic
        include ::apache2::mod::reqtimeout
        include ::apache2::mod::rewrite
        include ::apache2::mod::userdir
        include ::apache2::mod::version
        include ::apache2::mod::vhost_alias
        include ::apache2::mod::speling
        include ::apache2::mod::filter

        ::apache2::mod { 'asis': }
        ::apache2::mod { 'auth_digest': }
        ::apache2::mod { 'auth_form': }
        ::apache2::mod { 'authn_anon': }
        ::apache2::mod { 'authn_dbm': }
        ::apache2::mod { 'authn_socache': }
        ::apache2::mod { 'authz_dbd': }
        ::apache2::mod { 'authz_dbm': }
        ::apache2::mod { 'authz_owner': }
        ::apache2::mod { 'dumpio': }
        ::apache2::mod { 'expires': }
        ::apache2::mod { 'file_cache': }
        ::apache2::mod { 'imagemap':}
        ::apache2::mod { 'include': }
        ::apache2::mod { 'logio': }
        ::apache2::mod { 'request': }
        ::apache2::mod { 'session': }
        ::apache2::mod { 'unique_id': }
      }
      default: {}
    }
    case $::apache2::mpm_module {
      'prefork': {
        include ::apache2::mod::cgi
      }
      'worker': {
        include ::apache2::mod::cgid
      }
      default: {
        # do nothing
      }
    }
    include ::apache2::mod::alias
    include ::apache2::mod::authn_file
    include ::apache2::mod::autoindex
    include ::apache2::mod::dav
    include ::apache2::mod::dav_fs
    include ::apache2::mod::deflate
    include ::apache2::mod::dir
    include ::apache2::mod::mime
    include ::apache2::mod::negotiation
    include ::apache2::mod::setenvif
    ::apache2::mod { 'auth_basic': }

    if versioncmp($apache_version, '2.4') >= 0 {
      # filter is needed by mod_deflate
      include ::apache2::mod::filter

      # authz_core is needed for 'Require' directive
      ::apache2::mod { 'authz_core':
        id => 'authz_core_module',
      }

      # lots of stuff seems to break without access_compat
      ::apache2::mod { 'access_compat': }
    } else {
      include ::apache2::mod::authz_default
    }

    include ::apache2::mod::authz_user

    ::apache2::mod { 'authz_groupfile': }
    ::apache2::mod { 'env': }
  } elsif $mods {
    ::apache2::default_mods::load { $mods: }

    if versioncmp($apache_version, '2.4') >= 0 {
      # authz_core is needed for 'Require' directive
      ::apache2::mod { 'authz_core':
        id => 'authz_core_module',
      }

      # filter is needed by mod_deflate
      include ::apache2::mod::filter
    }
  } else {
    if versioncmp($apache_version, '2.4') >= 0 {
      # authz_core is needed for 'Require' directive
      ::apache2::mod { 'authz_core':
        id => 'authz_core_module',
      }

      # filter is needed by mod_deflate
      include ::apache2::mod::filter
    }
  }
}
