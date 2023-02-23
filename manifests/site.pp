node 'agent01.lab.com' {

	include common::users::developers_accounts::current_users
	include common::users::dev_group
	include common::motd::default

}
