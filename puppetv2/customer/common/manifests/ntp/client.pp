class common::ntp::client ($server_list, $ntpd_start_options = undef, $server_options = ' iburst', $sync_hwclock = true, $ntpdate_service_ensure = 'running',) {

	if $::operatingsystemmajrelease >= '7' {
		service { 'chronyd' :
			ensure	=> stopped,
			enable	=> false,
		}
	}

	class { "ntp":
		server_list        => $server_list,
		ntpd_start_options => $ntpd_start_options,
		server_options     => $server_options,
	}
	class { "ntp::ntpdate":
		server_list    => $server_list,
		sync_hwclock   => $sync_hwclock,
		service_ensure => $ntpdate_service_ensure,
	}
}
