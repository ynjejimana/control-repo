node 'agent01.lab.com' {

	include common::users::developers_accounts
	include common::users::dev_group
	include common::motd::default

}
