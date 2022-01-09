# Class: mule_runtime
# ===========================
#
# A Puppet module to install Mule Runtime server.
#
# Parameters 
# ----------
#
# * `mule_mirror` - Http mirror to download mule runtime archive from.
# * `mule_ver` - Mule version to download and install.
# * `mule_parent_dir` - Directory to install in. (eg. '/opt')
#
# Examples
# --------
#
# @example
#    node default {
#
#      class  { 'java':
#        distribution => 'jdk',
#        version      => 'latest',
#      }
#
#      class  { 'mule_runtime':
#        require => Class['java']
#      }
#
#    } 
#
# Authors
# -------
#
# Author Name <author@domain.com>
#
# Copyright
# ---------
#
# Copyright 2016 Your name here, unless otherwise noted.
#
class mule_runtime(

  $repo_server     = $mule_runtime::params::repo_server,
  $repo_path       = $mule_runtime::params::repo_path,
  $mule_ver        = $mule_runtime::params::mule_ver,
  $mule_parent_dir = $mule_runtime::params::mule_parent_dir,
  $java_home       = $mule_runtime::params::java_home,
  $user            = $mule_runtime::params::user,
  $group           = $mule_runtime::params::group,

) inherits mule_runtime::params {

  $dist_name = "mule-standalone-${mule_ver}"
  $mule_home = "${mule_parent_dir}/${dist_name}"
  $archive_url = "http://${repo_server}${repo_path}/${mule_ver}/${dist_name}.tar.gz"
  $archive = "/tmp/${dist_name}.tar.gz"

  archive { $archive:
    ensure           => present,
    extract          => true,
    extract_path     => '/opt',
    source           => $archive_url,
    user             => $user,
    group            => $group,
    creates          => $mule_home,
    cleanup          => false,  # leave downloaded file on the server 
  }

  file { "${mule_parent_dir}/mule":
    ensure  => 'link',
    target  => $mule_home,
    owner   => $user,
    group   => $group,
    require => Archive[$archive]
  }

  file { $mule_home:
    ensure  => directory,
    owner   => $user,
    group   => $group,
    recurse => true,
    require => Archive[$archive]
  }

  file { '/etc/profile.d/mule.sh':
    ensure  => present,
    mode    => '0644',
    content => "export MULE_HOME=${mule_home}",
    require => Archive[$archive]
  }

  file { '/etc/init.d/mule':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('mule_runtime/mule.init.erb'),
    require => Archive[$archive]
  }

  #service { 'mule':
  #  ensure    => running,
  #  enable    => true,
  #  require   => File['/etc/init.d/mule'],
  #  hasstatus => false
  #}

}
