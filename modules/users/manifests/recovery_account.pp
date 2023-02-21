class common::users::recovery_account ( $password, $admin_group = hiera("common::users::admin_group::group_name") ) {
  tag "autoupdate"

  require common::users::admin_group

  user { "vagrant":
    comment    => "Admin Non-key account",
    ensure     => present,
    managehome => true,
    home       => "/home/vagrant",
    uid        => "6000",
    gid        => $admin_group,
    password   => $password,
  }

  File {
    owner => "vagrant",
    group => $admin_group,
    require => User["vagrant"],
  }

  file { "/home/vagrant/.ssh":
    ensure => directory,
    mode   => '0700',
  }

  file { "/home/vagrant/.ssh/authorized_keys":
    ensure => file,
#    source => "puppet:///modules/common/users/puppetssh_id_rsa.pub",
    mode   => '0600',
  }
}

