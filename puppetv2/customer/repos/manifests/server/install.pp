class repos::server::install ($repos = {}, $is_master = false, $master_server = '172.16.40.21', $vhost_servers = {}) {
  tag 'autoupdate'

  file { '/var/www/html/repo':
    ensure => directory,
    owner  => 'apache',
    group  => 'apache',
  }

  # this is inplace as a temporary fix until the forge apache module is updated
  # this will allow centos7 machine to be used as repo server 
  if $::osfamily == 'RedHat' and $::operatingsystemmajrelease == '7' {
    package { ['httpd', 'httpd-tools']:
      ensure => installed,
    }
    service { 'httpd':
      ensure =>  running,
      enable =>  true,
    }
  } else {
    class {'apache': }
    create_resources('apache::vhost',$vhost_servers)
  }

  class {'rsync': }

  if $is_master == true {
    # Using an exec rather than a recursive directory block as it is much faster
    exec { 'fix-repo-permissions':
      command => '/bin/chown -R apache:apache /var/www/html/repo',
      user    => 'root',
    }

    package { ['yum-utils', 'createrepo']:
      ensure => installed,
    }

    $repos_defaults = {
      require => Exec['fix-repo-permissions'],
    }

    create_resources(repos::server::yum_repo, $repos, $repos_defaults)

    concat {'/etc/yum_reposync.conf':
      owner => root,
      group => root,
      mode  => '0644',
    }

    concat::fragment { 'reposync.conf.header':
      target  => '/etc/yum_reposync.conf',
      content => template('repos/server/yum_conf.header.erb'),
      order   => '01',
    }

    class { 'rsync::server': }

    rsync::server::module {'repo':
      path    => '/var/www/html/repo',
      require => File['/var/www/html/repo'],
    }
  }
  else {
    cron { 'sync-repo-from-master':
      command  => "/usr/bin/rsync -avz --delete rsync://${master_server}/repo/ /var/www/html/repo",
      user     => 'apache',
      month    => '*',
      monthday => '*',
      hour     => '3',
      minute   => '0',
    }
  }
}
