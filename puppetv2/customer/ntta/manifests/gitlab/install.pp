class ntta::gitlab::install (
	$site_url,
	$version,
	$ldap_basedn = "OU=one,OU=lab,OU=com,OU=au",
	$ldap_binddn = 'LAB\SVC-Gitlab',
	$ldap_server,
	$ldap_password,
	$projects_limit = 50
	) {
	case $::operatingsystem {
		"CentOS": {
			include repos::centos::centos_misc
		}
		default: { }
	}

	file { "/etc/init.d/gitlab-push":
		ensure => file,
		owner  => root,
		group  => root,
		mode   => '0770',
		source => "puppet:///modules/ntta/gitlab/gitlab-push",
		notify => Service["gitlab-push"],
	}

	file { "/var/opt/gitlab/git-data/repositories/gitlab_push.rb":
		ensure  => file,
		owner   => "git",
		group   => "git",
		mode    => '0770',
		source  => "puppet:///modules/ntta/gitlab/gitlab_push.rb",
		require => [ Package["rubygem-sinatra"], Package["rubygem-thin"] ],
		notify  => Service["gitlab-push"],
	}

	package { ["rubygem-sinatra", "rubygem-thin"]:
		ensure => installed,
	}

	service { "gitlab-push":
		ensure  => running,
		enable  => true,
		require => [ File["/etc/init.d/gitlab-push"], File["/var/opt/gitlab/git-data/repositories/gitlab_push.rb"] ],
	}

	class { "::gitlab":
		site_url       => $site_url,
		ldap_basedn    => $ldap_basedn,
		ldap_binddn    => $ldap_binddn,
		ldap_server    => $ldap_server,
		ldap_password  => $ldap_password,
		version        => $version,
		projects_limit => $projects_limit,
	}
}
