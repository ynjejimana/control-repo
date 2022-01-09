#$zabbix_mysql_user_parameters = []

class zabbix::mysql inherits zabbix {

	File {
		group   => $user,
		owner 	=> $group,
		mode  	=> "0600",
	}

	file {
		"${userparameter_config_dir}/userparameter_mysql.conf":
			content	=> template("zabbix/userparameter_mysql_conf.erb"),
			require => Package[$agent_package_name];
		"${user_home_dir}/.my.cnf":
			content 	=> template("zabbix/my.cnf.erb"),
     	require	  => [ Package[$agent_package_name], File[$user_home_dir] ];
	}

}
