class repos::centos::foreman inherits repos::params {
  if $::operatingsystem == 'CentOS' {
    package { 'foreman-release':
      ensure => absent,
    }

    yum_repo { 'foreman':
      baseurl  => "http://${repo_server}/repo/foreman/el${::operatingsystemmajrelease}",
    }
  }
}
