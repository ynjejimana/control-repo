class common::users::unix_accounts ($admin_group = hiera("common::users::admin_group::group_name"), $current_users, $former_users) {
	tag "autoupdate"

	require common::users::admin_group

	if defined(Class["common::users::ad_accounts"]) {
		fail("Cannot have both common::users::unix_accounts and common::users::ad_accounts on the same machine")
	}

	if defined(Class["common::ipa::client"]) {
		notify { "Skipping the addition of local accounts for unix in favour of IPA": }
	}
	else {

		$current_users_settings = {
			ensure => present,
			group => $admin_group,
		}
		create_resources(common::users::local_user, $current_users, $current_users_settings)
		$former_users_settings = {
			ensure 		=> absent,
			group 		=> $admin_group,
			managehome 	=> false,
		}
		create_resources(common::users::local_user, $former_users, $former_users_settings)
	}


}
