class repos::centos::puppetlabs inherits repos::params {
  if $::operatingsystem == 'CentOS' {
    exec { 'puppetlabs-release':
      command => '/usr/bin/yum -y remove puppetlabs-release',
    }

    yum_repo { 'puppetlabs-deps' :
      baseurl => "http://${repo_server}/repo/puppetlabs-deps/el${::operatingsystemmajrelease}",
    }
    yum_repo { 'puppetlabs-products' :
      baseurl => "http://${repo_server}/repo/puppetlabs-products/el${::operatingsystemmajrelease}",
    }
  }
}
