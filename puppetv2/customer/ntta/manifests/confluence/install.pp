class ntta::confluence::install (
	$backup_server = undef,
  $db_password,
  $db_root_password,
  $key_dname,
  $server_id,
  $license_hash,
  $license_message
	) {
	class { "::confluence":
	  db_password      => $db_password,
	  db_root_password => $db_root_password,
	  key_dname        => $key_dname,
	  server_id        => $server_id,
	  license_hash     => $license_hash,
	  license_message  => $license_message,
	}
  
  if $backup_server != undef {
	  class { "::ntta::confluence::cron":
	  	backup_server => $backup_server,
		}
  }
}