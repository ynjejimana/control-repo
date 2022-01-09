class repos::centos::scl inherits repos::params {
  if $::operatingsystem == 'CentOS' {
    yum_repo { 'scl' :
      baseurl => "http://${repo_server}/repo/centos/${::operatingsystemmajrelease}/scl/\$basearch",
    }
  }
}
