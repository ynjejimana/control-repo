class scm_manager::install ($site_url) inherits scm_manager::params {

	wget::fetch { $::scm_manager::params::warfile_dest :
		destination => $::scm_manager::params::warfile_dest,
		source      => $::scm_manager::params::warfile_source,
		execuser    => $::scm_manager::params::application_user,
		require     => Tomcat::Instance["scm-manager"],
	}

	file { ["${::scm_manager::params::instancedir}/.scm"] :
		ensure  => directory,
		owner   => $::scm_manager::params::application_user,
		group   => $::scm_manager::params::application_group,
		require => Tomcat::Instance["scm-manager"],
	}

	class { "tomcat": }

  tomcat::instance {"scm-manager":
    ensure           => present,
    ajp_port         => $::scm_manager::params::ajp_port,
    instance_basedir => $::scm_manager::params::installdir,
    setenv           => [
    	"SCM_HOME=${::scm_manager::params::instancedir}/.scm",
			'JAVA_XMX="1024m"',
			'ADD_JAVA_OPTS="-Xms128m"'
    ],
  }

	Apache::Vhost {
		docroot => $::scm_manager::params::docroot,
		servername => $site_url,
	}

	$proxy_pass_list = [
		{ 'path' => '/', 'url' => "ajp://localhost:${::scm_manager::params::ajp_port}/scm" },
	]

	class { "::apache": }

	class { "::apache::mod::proxy_ajp" : }

  apache::vhost { "${site_url}:80":
    port         => '80',
    rewrite_cond => '%{HTTPS} off',
    rewrite_rule => '(.*) https://%{HTTP_HOST}%{REQUEST_URI}',
  }

  apache::vhost { "${site_url}:443":
    port       => '443',
    ssl        => true,
    proxy_pass => $proxy_pass_list,
  }
}