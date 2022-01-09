class repos::cleanup {

	if $::osfamily == RedHat {
		file { "/etc/yum.repos.d":
			ensure  => directory,
			recurse => true,
			purge   => true,
		}
	
		File["/etc/yum.repos.d"] -> Yumrepo <| |>
	}
}
