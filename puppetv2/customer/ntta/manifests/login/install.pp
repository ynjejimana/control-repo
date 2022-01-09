class ntta::login::install ($vhost_name = undef, $docroot = undef)
{

	# Installs base apache
	class {"apache":
		default_vhost    => false,
		server_tokens    => 'ProductOnly',
		trace_enable     => 'off',
		timeout          => '60',
		serveradmin      => 'root@localhost',
		server_signature => 'Off',
    ports_file     => '/etc/httpd/conf/ports.conf',
	}

	apache::listen { '80': }


	#apache::vhost { $site_url :
	#	port => 80,
	#	docroot => "/var/www/html",
	#	options => ['-Indexes','FollowSymLinks','MultiViews'],
	#}

	apache::vhost{ $vhost_name:
    servername      => $vhost_name,
    port            => '80',
    docroot         => $docroot,
    access_log_file => "${vhost_name}_access.log",
    error_log_file  => "${vhost_name}_error.log",
    directories     => [
      {
        path           => $docroot,
        options        => ['-Indexes', 'FollowSymLinks', 'MultiViews'],
        allow_override => [ 'None' ],
        order          => 'Allow,Deny',
       }
    ]
  }

  $loginpackages = ["git"]
  package{ $loginpackages:
    ensure => present,
  }

  $git_source = hiera('ntta::login::install::git_source')

  if ($docroot){
    vcsrepo { $docroot:
      ensure   => present,
      provider => git,
      source   => $git_source,
      owner    => $::apache::params::user,
      group    => $::apache::params::group,
      require  => [Class["apache"], Package["git"]],
    }
  }

}
