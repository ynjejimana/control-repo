class common::timezone::config ($timezone, $copy = false) {
  tag "autoupdate"

  class { "::timezone" :
		timezone    => $timezone,
		autoupgrade	=> true,
		copy        => $copy,
	}
}
