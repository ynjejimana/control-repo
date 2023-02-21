class common::etcissue::default ($message = undef) {
	tag "autoupdate"

	if $message != undef {
		file {"/etc/issue":
			owner   => root,
			group   => root,
			mode    => "0644",
			content => $message,
		}
	}
}

