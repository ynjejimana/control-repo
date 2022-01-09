# Class: facl
#
# Main class, to start managing ACLs with the fooacl module.
#
# Sample Usage :
#  use the wrapper class 
#
class facl (
  $facl_noop      = false,
  $acl_package_name = $facl::params::acl_package_name,
) inherits facl::params {

  if $acl_package_name {
    package { $acl_package_name:
      ensure => 'present',
    }
  }

  $notify = $facl_noop ? {
    true  => undef,
    false => Exec['/usr/local/sbin/nttfacl'],
  }

  # Main script, to apply ACLs when the configuration changes
  exec { '/usr/local/sbin/nttfacl':
    refreshonly => true,
    require     => Package[$acl_package_name],
  }
  concat { '/usr/local/sbin/nttfacl':
    mode   => '0755',
    notify => $notify,
  }
  concat::fragment { 'facl-header':
    target  => '/usr/local/sbin/nttfacl',
    order   => 10,
    content => template("${module_name}/10.erb"),
  }
  concat::fragment { 'facl-footer':
    target  => '/usr/local/sbin/nttfacl',
    order   => 30,
    content => template("${module_name}/30.erb"),
  }

}
