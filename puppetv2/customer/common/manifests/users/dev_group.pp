# Sets the root password
class common::users::dev_group ($group_name) {
  tag "autoupdate"

  group { $group_name :
    ensure => present,
    gid    => 7000,
  }

  if !defined(Class["sudo"]) {
    class { "sudo" :
      ensure => present,
    }
  }

  sudo::conf { "labdevs" :
    ensure   => absent,
    priority => 20,
  }

 sudo::conf { "devs" :
    ensure   => present,
    priority => 30,
    content  => "%${group_name} ALL=NOPASSWD:/usr/bin/git\nDefaults:%${group_name} !requiretty",
  }

}
