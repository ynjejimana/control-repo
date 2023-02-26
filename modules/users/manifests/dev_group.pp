# Sets the root password
class modules::users::dev_group ($group_name) {
  tag "autoupdate"

  group { $group_name :
    ensure => present,
    gid    => 7000,
  }
}
