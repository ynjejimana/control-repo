class repos::centos::freeipa inherits repos::params {
	# No Centos6 IPA modules for version 4 of IPA are currently available
	# Freeipa client version 3 is being used on Centos 6 instead.
	if $::osfamily == "RedHat" and $::operatingsystemmajrelease == "7" {
		yum_repo { 'freeipa' :
			baseurl => "http://${repo_server}/repo/freeipa/4/el${::operatingsystemmajrelease}",
		}
	}
}
