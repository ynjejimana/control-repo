class confluence::db inherits confluence {

  # Installs MySQL server and sets root password for MySQL
  class { 'mysql::server':
    config_hash => { 'root_password' => $db_root_password },
    package_name => $server_package_name,
  }


  # Creates MySQL database with UTF-8 charset for Confluence
  mysql::db { $db_name :
    user     => $db_username,
    password => $db_password,
    host     => $db_host,
    charset  => 'utf8',
    grant    => ['all'],
	}

  # Sets MySQL options for Confluence (needs UTF-8 options set, etc.)
  # 
  # Note that this means the contents of the /etc/my.cnf do NOT need to be set by this class
  # The settings in this file will override the settings in /etc/my.cnf
  file { '/etc/mysql/conf.d/confluence.cnf':
    content => template('confluence/mysql/my.cnf.erb'),
  }

  # Updates server ID in Confluence database
	exec { "update-server-id":
		command       => "/bin/echo \"update BANDANA set BANDANAVALUE='<string>${server_id}</string>' where BANDANAKEY='confluence.server.id'\" | /usr/bin/mysql -N -D ${db_name} -u ${db_username} --password=${db_password} 2> /dev/null && touch ${installdir}/confluence_server_id_updated",
    notify      => Service[confluence],
    refreshonly => true,
    creates     => "${installdir}/confluence_server_id_updated",
    require     => Mysql::Db[$db_name],
	}
}
