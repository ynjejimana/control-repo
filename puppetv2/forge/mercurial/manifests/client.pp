class mercurial::client inherits mercurial::params {
	package { $package_name :
		ensure => installed,
	}
}