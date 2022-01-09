class common::cron::config () {
	$entries = hiera_hash('common::cron::config::entries', {})
	if $entries {
		create_resources('common::cron::job', $entries)
	}
}
