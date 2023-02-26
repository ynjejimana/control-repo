class motd::default ($message) {
	tag "autoupdate"

	file {"/etc/motd":
		owner   => root,
		group   => root,
		mode    => "0644",
		content => $message,
	}
}
