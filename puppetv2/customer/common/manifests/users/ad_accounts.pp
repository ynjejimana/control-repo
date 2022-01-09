class common::users::ad_accounts ($admin_group = hiera("common::users::admin_group::group_name"), $auth_domain = "one.lab.com.au", $ldap_filter = undef) {
  tag "autoupdate"

  require common::users::admin_group

  class { 'sssd':
    domains       => [$auth_domain],
    make_home_dir => true,
    filter_groups => ["root", $admin_group],
  }

  sssd::domain { $auth_domain :
    ldap_filter => $ldap_filter,
  }

  # This gives sudo access to every domain user, but SSSD will only
  # let users who pass the $ldap_filter into the box in the first place,
  # so this should not be a problem
  # 
  # This is to work around a bug in SSSD's secondary group lookups
  sudo::conf { "sssd" :
    ensure   => present,
    priority => 20,
    content  => '%domain\ users ALL=(ALL) NOPASSWD: ALL',
  }
}
