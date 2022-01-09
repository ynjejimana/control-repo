define mercurial::server::repo ($description, $read_only_users = undef, $read_write_users = undef, $mail_server, $from_email) {
	File {
		owner => $::apache::params::user,
		group => $::apache::params::group,
	}

	vcsrepo { "${::mercurial::server::repo_docroot}/${title}":
	  ensure   => present,
	  provider => hg,
 		owner    => $::apache::params::user,
		group     => $::apache::params::group,
	  notify   => Service['httpd'],
	}

	file { "${::mercurial::server::repo_docroot}/${title}/.hg/hgrc":
		ensure  => file,
		content => template("mercurial/hgrc.erb"),
		require => Vcsrepo["${::mercurial::server::repo_docroot}/${title}"],
		notify  => Service['httpd'],
	}
}