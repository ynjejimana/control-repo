class ntta::portal::install ($vhost_name = undef, $docroot = undef, $custom_fragment = undef)
{

  # Installs base apache
  class { "apache":
    default_vhost    => false,
    server_tokens    => 'ProductOnly',
    trace_enable     => 'off',
    timeout          => '60',
    serveradmin      => 'root@localhost',
    server_signature => 'Off',
    ports_file       => '/etc/httpd/conf/ports.conf',
  }

  apache::listen { '80': }

  #create vhosts if exists in hiera

  apache::vhost{ $vhost_name:
    servername      => $vhost_name,
    port            => '80',
    docroot         => $docroot,
    access_log_file => "${vhost_name}_access.log",
    error_log_file  => "${vhost_name}_error.log",
    directories     => [
      {
        path            => $docroot,
        options         => ['Indexes', 'FollowSymLinks', 'MultiViews'],
        allow_override  => [ 'None' ],
        order           => 'Allow,Deny',
        custom_fragment => $custom_fragment,
      }
    ]
  }

  #install packages
  $portalpackages = ["git","php-mysql","php-gd","php-soap","php-bcmath","php-xml","php-mbstring"]
  package{ $portalpackages:
    ensure => present,
  }

  #$docroot = hiera('ntta::portal::install::docroot',false)
  $git_source = hiera('ntta::portal::install::git_source')

  if ($docroot){
    vcsrepo { $docroot:
      ensure   => present,
      provider => git,
      source   => $git_source,
      #  source => "git@globgit01.esbu.lab.com.au:systems/nboss-lab-portal.git",
      #  source   => "git@${git_server}:shahidur.rahman/sfdocgen.git",
      owner    => $::apache::params::user,
      group    => $::apache::params::group,
      require  => [Class["apache"], Package["git"]],
    }
  }

  # Add filesystem ACL to apache::params::logroot
  $logroot = $::apache::params::logroot
  $readergroup = hiera('ntta::portal::install::log_reader_group')
  exec { "set-standard-logdir-facls":
    command	=> "/usr/bin/setfacl -d -m g:${readergroup}:r ${logroot}; /usr/bin/setfacl -m g:${readergroup}:r ${logroot}/*; /usr/bin/setfacl -m g:${readergroup}:rx ${logroot}",
    unless  => "/usr/bin/getfacl ${logroot} | grep ${readergroup} 2>/dev/null",
  }

  # Script to pull down latest version of code and gracefully restart apache
  file {'/usr/local/sbin/codepull-and-restart.sh':
    content	=> template("ntta/portal/codepull-and-restart.sh.erb"),
    owner   => "root",
    group   => "root",
    mode    => "0700",
  }

  # Enable members of devs group to run the above script
  sudo::conf { "devs2" :
    ensure   => present,
    priority => 40,
    content  => "%${readergroup} ALL=NOPASSWD:/usr/local/sbin/codepull-and-restart.sh\nDefaults:%${readergroup} !requiretty",
  }

  # Installs PHP module and configures PHP
  include apache::mod::php

  php::ini { "/etc/php.ini":
    max_execution_time  => "120",
    memory_limit        => "512M",
    upload_max_filesize => "8M",
    date_timezone       => "Australia/Sydney",
    short_open_tag      => "On",
    session_gc_maxlifetime => "7200",
  }

  php::module { ["pecl-apc"]: }

  php::module::ini { 'pecl-apc':
    settings => {
      'apc.enabled'      => '1',
      'apc.shm_segments' => '1',
      'apc.shm_size'     => '64',
    }
  }

}

