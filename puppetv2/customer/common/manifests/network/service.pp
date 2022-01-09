class common::network::service {
	tag "autoupdate"

	$service_name = $::osfamily ? {
		"redhat" => "network",
		default => undef,
	}

	if $service_name != undef {
		service { $service_name :
		  enable    => true,
			ensure     => running,
			hasrestart => true,
			hasstatus  => true,
		}
	}
}
