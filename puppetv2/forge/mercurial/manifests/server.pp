class mercurial::server ($service_url, $repos, $repo_docroot = "/var/hg", $apache_config = undef)
# apache_config only contains the extra config needed for things like LDAP authentication
# Puppet will configure the rest of the vhost config automatically
		inherits mercurial::params {
	class { 'apache' :}
	apache::vhost { $service_url :
		port            => '443',
		ssl             => true,
		docroot         => $repo_docroot,
		custom_fragment => $apache_config,
	}

	package { $package_name :
		ensure => installed,
	}

	File {
		owner => $::apache::params::user,
		group => $::apache::params::group,
	}

	file { $repo_docroot :
		ensure => directory,
	}

	file { "${repo_docroot}/hgweb.config" :
		content => template("mercurial/hgweb.config.erb"),
	}

	file { "${repo_docroot}/hgweb.cgi" :
		source => "puppet:///modules/mercurial/hgweb.cgi",
	}
}