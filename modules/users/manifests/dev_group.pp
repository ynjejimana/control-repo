# Sets the root password
class users::dev_group ($group_name) {
  tag "autoupdate"

  group { $group_name :
    ensure => present,
    gid    => 7000,
  }
}

