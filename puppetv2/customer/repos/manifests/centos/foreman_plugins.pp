class repos::centos::foreman_plugins inherits repos::params {
  if $::operatingsystem == 'CentOS' {
    yum_repo { 'foreman-plugins':
      baseurl  => "http://${repo_server}/repo/foreman-plugins/el${::operatingsystemmajrelease}",
    }
  }
}
