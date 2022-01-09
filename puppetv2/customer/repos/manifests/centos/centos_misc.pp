class repos::centos::centos_misc (
  $enabled = $repos::params::enabled
) inherits repos::params {
  if $::operatingsystem == 'CentOS' {
    yum_repo { 'centos-misc' :
      baseurl => "http://${repo_server}/repo/centos/${::operatingsystemmajrelease}/misc/\$basearch",
      enabled => $enabled,
    }
  }
}
