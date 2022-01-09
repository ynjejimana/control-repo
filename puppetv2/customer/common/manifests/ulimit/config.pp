# Class common::ulimit::config
#
# Uses the forge 'ulimit' classes to define ulimits.

class common::ulimit::config (
	$purge	 		= true,
	$use_default_ulimits	= true,
) {
	$ulimits = hiera_hash('common::ulimit::config::ulimits', {})
	include ::ulimit
	if $ulimits {
		create_resources('ulimit::rule', $ulimits)
	}
}
