class repos::centos::epel inherits repos::params {
  if $::operatingsystem == 'CentOS' {
    exec { 'epel-release':
      command => '/usr/bin/yum -y remove epel-release',
    }

    yum_repo { 'epel':
      baseurl  => "http://${repo_server}/repo/epel/${::operatingsystemmajrelease}",
    }
  }
}
