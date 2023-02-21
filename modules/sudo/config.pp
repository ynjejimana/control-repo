class common::sudo::config (
){
	$sudoer_configs = hiera_hash('common::sudo::config::sudoer_configs', {})
	include ::sudo
	if $sudoer_configs {
		create_resources('sudo::conf', $sudoer_configs)
	}
}

