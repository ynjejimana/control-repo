class confluence::ssl inherits confluence {

	$keytool = "${installdir}/confluence/jre/bin/keytool"

	File {
		owner => "confluence",
		group => "confluence",
		mode => "0750",
	}

	Exec {
		user => "root",
	}

	# Sets certificate for Confluence
	file { $sslcert:
		ensure  => present,
		source  => "puppet:///modules/confluence/lab.cer",
		require => Exec["install-confluence"],
	}

	# Generates server key for Confluence Java keystore
	exec { "generate-tomcat-key":
		command => "${keytool} -genkeypair -alias tomcat -keyalg RSA -dname \"${key_dname}\" -keystore ${confluence_keystore} -storepass ${keystore_passphrase} -noprompt",
		require => Exec[install-confluence],
		unless  => "${keytool} -list -keystore ${confluence_keystore} -storepass ${keystore_passphrase} | grep tomcat 2> /dev/null",
	}

	# Adds certificate to Confluence Java keystore
	exec { "install-ad-certificate":
		command => "${keytool} -importcert -trustcacerts -noprompt -alias ${key_alias} -keystore ${cacerts_keystore} -storepass ${keystore_passphrase} -file ${sslcert}",
		require => [ File[$sslcert], Exec[install-confluence] ],
		unless  => "${keytool} -list -keystore ${cacerts_keystore} -storepass ${keystore_passphrase} | grep ${key_alias} 2> /dev/null",
	}

	# Sets Confluence Tomcat server.xml and web.xml filess with keystore variables
	file { "${installdir}/confluence/conf/server.xml":
		ensure  => present,
		content => template("confluence/server.xml.erb"),
		require => Exec[install-confluence],
		mode    => "0644",
		notify  => Service[confluence],
	}
}
