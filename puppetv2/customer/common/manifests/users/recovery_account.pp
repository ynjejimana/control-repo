class common::users::recovery_account ( $password, $admin_group = hiera("common::users::admin_group::group_name") ) {
  tag "autoupdate"

  require common::users::admin_group

  user { "lab":
    comment    => "Admin Non-key account",
    ensure     => present,
    managehome => true,
    home       => "/home/lab",
    uid        => "6000",
    gid        => $admin_group,
    password   => $password,
  }

  File {
    owner => "lab",
    group => $admin_group,
    require => User["lab"],
  }

  file { "/home/lab/.ssh":
    ensure => directory,
    mode   => '0700',
  }

  file { "/home/lab/.ssh/authorized_keys":
    ensure => file,
    source => "puppet:///modules/common/users/puppetssh_id_rsa.pub",
    mode   => '0600',
  }
}
