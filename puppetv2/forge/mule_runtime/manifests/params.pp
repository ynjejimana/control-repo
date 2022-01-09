class mule_runtime::params {

  case $::osfamily {

    'Redhat', 'Debian': {
      $repo_server = hiera("repo_server")
      $repo_path = '/repo/mule/distributions/mule-standalone'
      $mule_ver = '3.8.1'
      $mule_parent_dir = '/opt'
      $java_home = '/usr/lib/jvm/java'
      $user = 'root'
      $group = 'root'
    }

    default: {
      fail("Module ${module_name} is not supported on ${::osfamily}")
    }

  }

}
