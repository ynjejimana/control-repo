class common::clamav::agent::scan (

) inherits common::clamav::agent {


  if $clamDaemonEnabled == true {

    $daemonPackageState       = 'latest'
    $daemonConfState          = 'present'
    $daemonScanState          = 'present'
    $daemonScanLogFileState   = 'present'
    $plainCronState           = 'absent'
    $plainScanState           = 'absent'
    $freshclamcCronState      = 'present'

    service { $svcs_daemon:
      enable                  => true,
      ensure                  => 'running',
      subscribe               => [Package[$pkgs_daemon], File[$clamdConfFile]],
    }

    if $clamScanEnabled == true {

      $daemonCronState        = 'present'

    } else {

      $daemonCronState        = 'absent'

    }

  } else {

    $daemonPackageState       = 'absent'
    $daemonCronState          = 'absent'
    $daemonConfState          = 'absent'
    $daemonScanState          = 'absent'
    $daemonScanLogFileState   = 'absent'
    $plainScanState           = 'present'
    $freshclamcCronState      = 'absent'

    if $clamScanEnabled == true {
      
      $plainCronState         = 'present'

    } else {

      $plainCronState         = 'absent'

    }
  }

  package { $pkgs_daemon:
    ensure                    => $daemonPackageState,
  } ->
  file { $clamdConfFile:
    content                   => template('common/clamav/agent_scan_conf.erb'),
    ensure                    => $daemonConfState,
    mode                      => 0644,
    owner                     => 'root',
    group                     => 'root',
    selinux_ignore_defaults   => true,
  } ->
  file { $scanClamScanLogFile:
    ensure                    => 'present',
    mode                      => 0644,
    owner                     => 'root',
    group                     => 'root',
    selinux_ignore_defaults   => true,
  } ->
  file { $scanLogFile:
    ensure                    => $daemonScanLogFileState,
    mode                      => 0644,
    owner                     => 'root',
    group                     => 'root',
    selinux_ignore_defaults   => true,
  } ->
  file { '/usr/local/bin/clamdscan.sh':
    content                   => template('common/clamav/agent_clamdscan_cron.erb'),
    ensure                    => $daemonScanState,
    mode                      => 0755,
    owner                     => 'root',
    group                     => 'root',
    selinux_ignore_defaults   => true,
  } ->
  cron { 'clamdscan':
    command                   => "/usr/bin/perl -le 'sleep rand 7200'; /usr/local/bin/clamdscan.sh > /dev/null 2>&1",
    user                      => 'root',
    hour                      => 2,
    minute                    => 0,
    ensure                    => $daemonCronState,
  } ->
  file { '/usr/local/bin/clamscan.sh':
    content                   => template('common/clamav/agent_clamscan_cron.erb'),
    ensure                    => $plainScanState,
    mode                      => 0755,
    owner                     => 'root',
    group                     => 'root',
    selinux_ignore_defaults   => true,
  } ->
  cron { 'freshclam':
    command                 => "/usr/bin/perl -le 'sleep rand 3600'; /usr/local/bin/freshclam.sh > /dev/null 2>&1",
    user                    => 'root',
    hour                    => 1,
    minute                  => 0,
    ensure                  => $freshclamcCronState,
  } ->
  cron { 'clamscan':
    command                   => "/usr/bin/perl -le 'sleep rand 7200'; /usr/local/bin/clamscan.sh > /dev/null 2>&1",
    user                      => 'root',
    hour                      => 2,
    minute                    => 0,
    ensure                    => $plainCronState,
  }
}

