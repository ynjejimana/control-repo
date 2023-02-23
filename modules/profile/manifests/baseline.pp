class profile::baseline (
  String $svcname
) {

  service { $svcname:
    ensure => 'running',
    enable => 'true',
  }
}
