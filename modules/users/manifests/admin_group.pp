# Sets the root password
class common::users::admin_group ($group_name) {
  tag "autoupdate"

  group { $group_name :
    ensure => present,
    gid    => 5000,
  }

  if !defined(Class["sudo"]) {
    class { "sudo" :
      ensure => present,
    }
  }

  sudo::conf { "labadmins" :
    ensure   => absent,
    priority => 20,
  }

  sudo::conf { "admins" :
    ensure   => present,
    priority => 20,
    content  => "%${group_name} ALL=(ALL) NOPASSWD: ALL\nDefaults:%${group_name} !requiretty",
  }
}

