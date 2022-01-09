class confluence::install inherits confluence {

	File {
		owner => "root",
		group => "root",
	}

	file { $confluence_dirs:
		ensure => directory,
	}

	# Dowloads install file from repo server set at $repo_server

	exec { "download-installer":
		command => "/usr/bin/wget http://${repo_server}/repo/confluence/${installer_file} -O ${installer}",
		require => File[$installdir],
		creates => $installer,
	}


	file { $installer:
		mode    => '0770',
		require => Exec[download-installer],
	}

	file { "${installdir}/confluence/confluence/WEB-INF/lib/mysql-connector-java-5.1.38-bin.jar" :
		source  => "puppet:///modules/confluence/mysql-connector-java-5.1.38-bin.jar",
		require => Exec[install-confluence],
		notify  => Service["confluence"],
	}

	# Sets contents of answer file for Confluence install
	file { $varfile :
		ensure  => present,
		source  => "puppet:///modules/confluence/response.varfile",
		mode    => "0640",
		require => File[$installdir],
	}

	# Sets contents of answer file for Confluence install
	file { "/etc/init.d/confluence" :
		ensure  => present,
		content => template("confluence/confluence.init.erb"),
		mode    => "0755",
		require => Exec[install-confluence],
	}

	exec { "install-confluence":
	 	command => "${installer} -q -varfile ${varfile} && touch ${installdir}/confluence_installed",
	 	cwd     => $installdir,
	 	require => [ File[$varfile], Exec[download-installer] ],
	 	creates => "${installdir}/confluence_installed",
	 	notify  => [ Exec["java memory fix"], Exec["install-ad-certificate"], Exec["generate-tomcat-key"], Exec["change installdir owner"] ],
	 }

	file { "/var/log/confluence":
	 	ensure  => link,
	 	target  => "${installdir}/confluence/logs",
	 	require => Exec[install-confluence],
	}

	# A fix required to set the amount of memory used by Confluence
	exec { "java memory fix" :
    command     => "/bin/sed -i 's/Xmx1024m/Xmx4096m/g' /opt/atlassian/confluence/bin/setenv.sh; /bin/sed -i 's/Xms1024m/Xms4096m/g' /opt/atlassian/confluence/bin/setenv.sh ",
    require     => Exec[install-confluence],
    refreshonly => true,
  }

        exec { "change installdir owner":
          command => "/bin/chown -R confluence.confluence ${installdir}/confluence && /bin/chmod -R u=rwX,go-rwx ${installdir}/confluence",
          refreshonly => true,

    }


	service { "confluence":
	  enable    => true,
		ensure     => running,
		hasrestart => true,
		hasstatus  => false,
		require    => Exec[install-confluence],
	}

	# Sets contents of confluence.cfg.xml after install has completed
	#
	# The install process requires the user to manually run through the confluence
	# setup process, which is done through a web browser
	# A custom fact reads the confluence config files to check which parts of the
	# setup process the user is up to
	# After the setup is completed, the contents of this file will be set by Puppet
	#
	# This means that, in production, Puppet may need to be run more than once

	if $confluence_setup_step == "complete" {
    augeas {"confluence.cfg.xml":
    	lens    => "Xml.lns",
    	incl    => "${homedir}/application-data/confluence/confluence.cfg.xml",
    	changes => ["set confluence-configuration/properties/property[#attribute/name='confluence.setup.server.id']/#text ${server_id}",
								 	"set confluence-configuration/properties/property[#attribute/name='confluence.license.hash']/#text ${license_hash}",
    	    	     	"set confluence-configuration/properties/property[#attribute/name='confluence.license.message']/#text ${license_message}"
    	    	     ],
  	}
  }
}
