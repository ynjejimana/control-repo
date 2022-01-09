class mercurial::params {
	case $osfamily {
		"RedHat": {
			$package_name = "mercurial"
		}
		default: {
			$package_name = "mercurial"
		}
	}
}