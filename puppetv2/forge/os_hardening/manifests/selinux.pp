class os_hardening::selinux( $mode = 'permissive', $type = 'targeted', ){

	if $::osfamily == 'RedHat' {
		file { '/etc/selinux/config':
			ensure  => file,
			content => template("${module_name}/selinux_${::operatingsystemmajrelease}.erb"),
			owner   => 'root',
			group   => 'root',
			mode    => '0644',
		}
	}

}
