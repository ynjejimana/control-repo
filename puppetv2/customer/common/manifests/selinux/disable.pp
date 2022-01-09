class common::selinux::disable {
	tag "autoupdate"

	class { "selinux" :
		mode => "permissive",
	}
}
