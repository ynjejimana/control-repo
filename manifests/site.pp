node 'agent01.lab.com' {

	include users::developers_accounts
	include users::dev_group
	include motd::default

}
