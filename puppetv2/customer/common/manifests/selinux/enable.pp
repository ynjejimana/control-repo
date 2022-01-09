class common::selinux::enable {
	tag "autoupdate"

	class { "selinux" :
		mode => "enabled",
	}
}
