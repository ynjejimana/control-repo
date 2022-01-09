class repos::centos::centos
(
  $enabled = $repos::params::enabled,
) inherits repos::params {
  if $::operatingsystem == 'CentOS' {
    yum_repo { 'centos-os' :
      baseurl => "http://${repo_server}/repo/centos/${::operatingsystemrelease}/os/\$basearch",
      enabled => $enabled,
    }
    yum_repo { 'centos-updates' :
      baseurl => "http://${repo_server}/repo/centos/${::operatingsystemrelease}/updates/\$basearch",
      enabled => $enabled,
    }
    yum_repo { 'centos-extras' :
      baseurl => "http://${repo_server}/repo/centos/${::operatingsystemrelease}/extras/\$basearch",
      enabled => $enabled,
    }

#    file { '/etc/yum.repos.d/centos-updates.repo':
#    ensure => absent,
#    }
  
  }
}
