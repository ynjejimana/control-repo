class soe::repos (
	$legacy = false,
){


	if defined(Class['soe::legacy_linux']) or $legacy {
		if $::operatingsystem == 'CentOS' {
			contain repos::centos::centos_misc
			contain repos::centos::centos
			contain repos::centos::epel
			contain repos::centos::freeipa
			contain repos::centos::puppetlabs
			contain repos::centos::scl
		}
	} else {
		if $::osfamily == "RedHat" {
			if $::operatingsystem == "RedHat" {
			 	contain common::rhsatellite::client
			} else {
				# this should include CentOS and OEL
				contain common::spacewalk::client
			}
		}
	}

	Class['soe::repos'] -> Package <| |>
}
