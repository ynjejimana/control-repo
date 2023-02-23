class common::users::developers_accounts ($dev_group = hiera("common::users::dev_group::group_name"), $current_users, $former_users) {
	tag "autoupdate"

	require common::users::dev_group

	$current_users_settings = {
		ensure => present,
		group => $dev_group,
	}

	create_resources(common::users::local_user, $current_users, $current_users_settings)

	$former_users_settings = {
		ensure => absent,
		group => $dev_group,
	}

	create_resources(common::users::local_user, $former_users, $former_users_settings)
}

