class confluence (
  $installdir = $::confluence::params::installdir,
  $installer_file = $::confluence::params::installer_file,
  $installer = $::confluence::params::installer,
  $varfile = $::confluence::params::varfile,
  $homedir = $::confluence::params::homedir,
  $confluence_dirs = $::confluence::params::confluence_dirs,
  $db_host = $::confluence::params::db_host,
  $db_username = $::confluence::params::db_username,
  $db_port = $::confluence::params::db_port,
  $db_name = $::confluence::params::db_name,
  $db_password = $::confluence::params::db_password,
  $db_root_password = $::confluence::params::db_root_password,
  $sslcert = $::confluence::params::sslcert,
  $keystore = $::confluence::params::keystore,
  $keystore_passphrase = $::confluence::params::keystore_passphrase,
  $key_alias = $::confluence::params::key_alias,
  $key_dname = $::confluence::params::key_dname,
  $server_id = $::confluence::params::server_id,
  $license_message = $::confluence::params::license_message,
  $license_hash = $::confluence::params::license_hash,
  $repo_server = $::confluence::params::repo_server,
  $server_package_name = $::confluence::params::server_package_name,
  $client_package_name = $::confluence::params::client_package_name,
 ) inherits confluence::params {
	include confluence::install, confluence::ssl
  if $db_host == "localhost" {
    include confluence::db
  }
}
