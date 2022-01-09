class ntta::jabber::server (
	$domains,
  $auth_method = "local",
  $ldap_servers = undef,
  $ldap_rootdn = undef,
  $ldap_password = undef,
  $ldap_base = undef,
  $ldap_filter = undef,
  $ssl_certificate = "puppet:///modules/ntta/jabber/ssl.pem",
	) {
	
	class {"ejabberd":
		domains       => $domains,
		auth_method   => $auth_method,
		ldap_filter   => $ldap_filter,
		ldap_base     => $ldap_base,
		ldap_password => $ldap_password,
		ldap_rootdn   => $ldap_rootdn,
		ldap_servers  => $ldap_servers,
	}

	if $auth_method == "ad" {
		file {"/etc/ejabberd/ejabberd.pem":
			ensure => file,
			source => $ssl_certificate,
			owner  => "ejabberd",
			group  => "ejabberd",
			mode   => "0400",
			notify => Service["ejabberd"],
		}
	}
}
