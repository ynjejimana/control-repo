class ntta::sfdocgen::install ($site_url)
{
  $git_server = hiera("git_server")

	# Installs base apache
	class {"apache": }

	# Installs Apache vhost for sfdocgen
	apache::vhost { $site_url :
		port    => 80,
		docroot => "/var/www/html/sfx",
	}

	# Installs PHP module and configures PHP
	class { "apache::mod::php": }

	# Extra parameters requested by Shahid
	php::ini { "/etc/php.ini":
		max_execution_time      => "120",
		memory_limit            => "512M",
		upload_max_filesize     => "8M",
		soap_wsdl_cache_enabled => '1',
  	soap_wsdl_cache_dir    => '/tmp',
  	soap_wsdl_cache_ttl    => '86400',
    session_gc_maxlifetime => "7200",
	}

	php::module { ["pecl-apc", "soap", "xml"]: }

	php::module::ini { "pecl-apc": }

	# Adds apc.php file to site docroot
  #file { "/var/www/html/sfdocgen/apc.php":
  #	ensure => file,
  #	source => "puppet:///modules/ntta/sfdocgen/apc.php",
  #	owner => $::apache::params::user,
  #	group => $::apache::params::group,
  #	require => Vcsrepo["/var/www/html/sfdocgen"],
  #}

	package { "git":
		ensure => installed,
	}

	# Checks out site code from Git
	vcsrepo { '/var/www/html/sfx':
	  ensure   => present,
	  provider => git,
	  source   => "git@${git_server}:systems/sfx.git",
	  owner    => $::apache::params::user,
	  group    => $::apache::params::group,
	  require  => [Class["apache"], Package["git"]],
	}
}
