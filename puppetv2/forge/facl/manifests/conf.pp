# Define: facl::conf
#
# Configure the Posix ACLs set by the script from the facl class.
#
define facl::conf (
  $permissions,
  $target      = $name,
  $order       = 20,
) {

  include ::facl

  concat::fragment { $title:
    target  => '/usr/local/sbin/nttfacl',
    order   => $order,
    content => template("${module_name}/20.erb"),
  }

}
