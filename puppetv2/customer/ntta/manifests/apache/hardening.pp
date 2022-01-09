class ntta::apache::hardening ($site_url = $::fqdn)
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


	apache::vhost { $site_url :
		port    => 80,
		docroot => "/var/www/html",
		options => ['-Indexes','FollowSymLinks','MultiViews'],
	}

}
