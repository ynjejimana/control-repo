# Class: facl::params
#
# Per-platform parameters for fooacl class
#
class facl::params {
  case $::osfamily {
    'gentoo': {
      $acl_package_name = 'sys-apps/acl'
    }
    default: {
      $acl_package_name = 'acl'
    }
  }
}
