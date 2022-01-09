class ejabberd(
  $domains = [$::fqdn],
  $auth_method = "local",
  $ldap_servers = undef,
  $ldap_rootdn = undef,
  $ldap_password = undef,
  $ldap_base = undef,
  $ldap_uids = undef,
  $ldap_filter = undef,
) {
	package {"ejabberd":
		ensure => installed,
	}

	file {"/etc/ejabberd/ejabberd.cfg":
		require => Package["ejabberd"],
		notify  => Service["ejabberd"],
		owner   => ejabberd,
		group   => ejabberd,
		mode    => "0640",
		content => template("ejabberd/ejabberd.cfg.erb"),
	}
	
	service { "ejabberd":
		ensure    => running,
		enable    => true,
		hasstatus => true,
		require   => Package["ejabberd"],
	}
}
