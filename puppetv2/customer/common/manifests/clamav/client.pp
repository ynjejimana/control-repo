class common::clamav::client (
  $clamav_package = 'clamav',
  $clamuser = 'clam',
  $avproxy_server = undef,
  $clamav_client = undef,
  $clamav_move_dir = undef,
) {

  if $clamav_client == 'enabled' {
    $exclude_dir =  hiera_array('common::clamav::client::exclude_dir', [])
    $exclude_files =  hiera_array('common::clamav::client::exclude_files', [])
    $other_options =  hiera_array('common::clamav::client::other_options', [])
    package { $clamav_package:
      ensure  =>  installed,
    }

    if $::osfamily == 'RedHat' {
      if $::operatingsystemmajrelease == '7' {
        package { 'clamav-update':
          ensure  =>  installed,
        }
      }
    }

    if $clamav_move_dir {
      file  { $clamav_move_dir:
        ensure =>  directory,
        owner  =>  root,
        group  =>  root,
        mode   =>  '0644',
      }
    }

    file  { '/etc/freshclam.conf':
      ensure  =>  file,
      content =>  template('common/clamav/client_freshclam_conf.erb'),
      owner   =>  root,
      group   =>  root,
      mode    =>  '0644',
      require =>  Package['clamav'],
    }

    file  { '/etc/cron.daily/freshclam':
      ensure  =>  absent,
      require =>  File['/etc/freshclam.conf'],
    }

    file  { '/var/spool/cron/clam':
      ensure  =>  absent,
      require =>  File['/etc/freshclam.conf'],
    }

    file  { '/etc/cron.d/clamav.cron':
      ensure  =>  file,
      content =>  template('common/clamav/client_clamav_cron.erb'),
      owner   =>  root,
      group   =>  root,
      mode    =>  '0755',
      require =>  File['/etc/freshclam.conf'],
    }

    cron  { 'clamscan':
      command =>  "/usr/bin/perl -le 'sleep rand 7200'; /etc/cron.d/clamav.cron",
      user    =>  'root',
      hour    =>  '2',
      minute  =>  0,
      require =>  File['/etc/freshclam.conf'],
    }
  }
}
