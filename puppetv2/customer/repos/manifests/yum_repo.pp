define repos::yum_repo (
	$descr = undef,
	$baseurl = undef,
	$enabled = '1',
	$gpgkey = undef,
	$gpgcheck = '0',
	$mirrorlist = undef
	) {
	file { "/etc/yum.repos.d/${name}.repo" :
		ensure => file,
	}

	require repos::cleanup

	yumrepo { $name :
		baseurl    => $baseurl,
		descr      => "${name} repository",
		enabled    => $enabled,
		gpgcheck   => $gpgcheck,
		gpgkey     => $gpgkey,
		mirrorlist => $mirrorlist,
	}

	File["/etc/yum.repos.d/${name}.repo"] -> Yumrepo <| |>
	#Yumrepo <| |> -> Package <| |>
}
