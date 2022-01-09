class ntta::wfr::install {
#######
# taken from https://git.lab.com.au/alen.stanisic/wfr_vagrant_puppet/tree/master
#######

###########################################################################################
  $wfrpackages = ['unixODBC', 'unixODBC-devel', 'gcc', 'gcc-c++','git', 'freetds', 'freetds-devel', 'openldap', 'openldap-devel', 'python-virtualenv', 'httpd', 'mod-ssl', 'mod_wsgi' ]
  $virtualenv_path = '/home/django/pyenv'
  $virtualenv_user = 'django'

########install required packages #########################################################
  package {$wfrpackages:
        ensure => 'installed',
  }

  service { 'httpd':
      ensure => running,
      require => Package['httpd'],
  }

############################################################################################

#configure django user
  user { 'django':
    ensure => present,
    comment => 'Django',
    #groups => ['apache'],
    home => '/home/django',
    managehome => true,
    shell => '/bin/bash',
  }->
  file { '/home/django':
    ensure => directory,
    mode => 0711,
  }->
  file { '/home/django/.ssh':
    ensure => directory,
    owner => django,
    group => django,
    mode => 0700,
  }

############################################################################################
##### configure pyvirtualenv #####

exec { 'pyenv-create':
    command => "/usr/bin/virtualenv ${virtualenv_path}",
    #command => "virtualenv ${virtualenv_path}",

    # run command as user
    user => "${virtualenv_user}",

    # only run command if pyenv does not exist
    creates => "$virtualenv_path",
    require => Package['python-virtualenv']
  }

#### installs and configure postgresql #########

class { 'postgresql::globals':
    #manage_package_repo => true,
    #version             => '9.3',
    encoding => 'UTF8',
    #pg_hba_conf_defaults => false,
  } ->
  class { 'postgresql::server':
    listen_addresses  => 'localhost',
    postgres_password => 'funkytown',
  }

  postgresql::server::db { 'webfinrep':
    user     => 'django',
    password => postgresql_password('django', 'django'),
  }

  postgresql::server::db { 'webfinrep_backoffice':
    user     => 'djangobo',
    password => postgresql_password('djangobo', 'djangobo'),
  }

  package { 'postgresql-devel':
    ensure => installed
  }

  file_line { 'pg_hba local md5 update':
    path => '/var/lib/pgsql/data/pg_hba.conf',
    line => "local\tall\tdjango\t\tmd5\nlocal\tall\tdjangobo\t\tmd5",
    match => "^local\tall\tall.*$",
  }
  



}
