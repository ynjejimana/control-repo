class ntta::web::install ($site_url)
{
	$git_server = hiera("git_server")

	# Installs base apache
	class {"apache":
		default_vhost => false,
		ports_file    => '/etc/httpd/conf/ports.conf',
		server_tokens => 'ProductOnly',
		trace_enable  => 'off',
		timeout       => '60',
		serveradmin   => 'root@localhost',
	}

	# Installs Apache vhost for lab
	apache::vhost { 'https.www-qat.lab.com' :
		priority            => 01,
		port                => "443",
		docroot             => "/var/www/html/lab",
		docroot_owner       => "apache",
		docroot_group       => "apache",
		ssl                 => true,
		ssl_cert            => "/etc/ssl/certs/qat.lab.com.pem",
		ssl_key             => "/etc/ssl/certs/qat.lab.com.key",
		additional_includes => "conf/www-qat.lab.com.conf",
	}
	apache::vhost { 'http.www-qat.lab.com' :
    priority          => 02,
		port                => "80",
		docroot             => "/var/www/html/lab",
		additional_includes => "conf/www-qat.lab.com.conf",
	}
	file { '/etc/httpd/conf.d/00-default.conf':
	ensure => file,
	source => "puppet:///modules/ntta/web/00-default.conf",
  owner => root,
  group => root,
  mode  => '0644',
	}

	# Installs PHP module and configures PHP
	class { "apache::mod::php": }

	# Extra parameters
	php::ini { "/etc/php.ini":
		max_execution_time      => "120",
		memory_limit            => "512M",
		upload_max_filesize     => "8M",
		soap_wsdl_cache_enabled => '1',
  	soap_wsdl_cache_dir    => '/tmp',
  	soap_wsdl_cache_ttl    => '86400',
		date_timezone           => 'Australia/Sydney',
	}
	file_line { 'session_cookie_httponly':
		path  => '/etc/php.ini',
		line  => 'session.cookie_httponly = true',
		match => '^session.cookie_httponly*',
	}

	php::module { ["pecl-apc", "soap", "xml", "gd", "mbstring", "mysql", "mcrypt", "devel"]: }

	php::module::ini { "pecl-apc": }

	# Adds apc.php file to site docroot
	file { "/var/www/html/apc.php":
		ensure => file,
		source => "puppet:///modules/ntta/sfdocgen/apc.php",
		owner  => $::apache::params::user,
		group  => $::apache::params::group,
	}

	file { "/var/www/html/index.html":
		ensure => file,
		source => "puppet:///modules/ntta/web/index.html",
		owner  => $::apache::params::user,
		group  => $::apache::params::group,
	}

	file { "/etc/httpd/conf.d/httpd.conf":
		ensure => file,
		source => "puppet:///modules/ntta/web/httpd.conf",
		owner  => $::apache::params::user,
		group  => $::apache::params::group,
	}

	file { "/var/www/html/lab/_ss_environment.php":
		ensure => file,
		source => "puppet:///modules/ntta/web/_ss_environment.php",
		owner  => apache,
		group  => apache,
		mode   => '0644',
	}

	package { ["git","subversion","mysql","mysql-server","mysql-devel"]:
		ensure => installed,
	}

	# make SVN to use proxy
	file { "/root/.subversion":
	ensure => "directory",
	}
	file { '/root/.subversion/servers':
	ensure => file,
	source => "puppet:///modules/ntta/web/servers",
  owner => root,
  group => root,
  mode  => '0755'
	}

	# Install custom my.cnf config file
	file { '/etc/my.cnf':
  ensure => file,
  source => "puppet:///modules/ntta/web/my.cnf",
  owner  => root,
  group  => root,
  mode   => '0644',
	require => Package['mysql-server'],
  }

	# Ensure mysqld starts during boot and restarts if my.cnf is changed
	service { 'mysqld':
	enable     => true,
  ensure    => running,
  subscribe => File["/etc/my.cnf"],
	}

	file { '/etc/httpd/conf/www-qat.lab.com.conf':
  ensure => file,
  source => "puppet:///modules/ntta/web/www-qat.lab.com.conf",
  owner  => root,
  group  => root,
  mode   => '0644'
  }

	exec { "generate_ssl_cert":
		command => '/usr/bin/openssl req -new -x509 -days 365 -nodes -out /etc/ssl/certs/qat.lab.com.pem -keyout /etc/ssl/certs/qat.lab.com.key -subj "/C=AU/ST=New South Wales/L=Sydney/O=LAB/CN=Webserver"',
		creates => "/etc/ssl/certs/qat.lab.com.pem",
	}

}
