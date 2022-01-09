class confluence::params {
	
	# Confluence install parameters
	$installdir="/opt/atlassian"
	$installer_file="atlassian-confluence-5.8.18-x64.bin"
	$installer="${installdir}/${installer_file}"
	$varfile="${installdir}/response.varfile"
	$homedir="/var/atlassian"
	$confluence_dirs = [$installdir, $homedir]
	
	# DB parameters
	$db_host = "localhost"
	$db_username = "confluence"
	$db_port = "3306"
	$db_name = "confluence"

	# SSL setup parameters
	$sslcert = "/home/confluence/lab.cer"
	$confluence_keystore = "/home/confluence/.keystore"
	$cacerts_keystore = "${installdir}/confluence/jre/lib/security/cacerts"
	$keystore_passphrase = "changeit"
	$key_alias = "labsslcert"

	$repo_server = "globrepo01.esbu.lab.com.au"
}
