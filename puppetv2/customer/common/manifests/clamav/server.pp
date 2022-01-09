# Clamav proxy server setup

class common::clamav::server (
  $avproxy_server = '',
  $avproxy_port = '',
) {
  if $::osfamily == 'RedHat' {
    if $::operatingsystemmajrelease == '7' {
      package { 'clamav-update':
        ensure  =>  installed,
        require =>  Package['clamav'],
        }
      }
    $clamuser = $::operatingsystemmajrelease ? {
      '6'     =>  'clam',
      '7'     =>  'clamupdate',
      default =>  'clam',
    }
    }
    package { 'clamav':
      ensure  =>  installed,
      require =>  Package['httpd'],
    }
    
    package { 'httpd':
      ensure  =>  installed,
    }
    
    file  { '/etc/httpd/conf.d/clamav.conf':
      ensure  =>  file,
      content =>  template('common/clamav/httpd_clamav_conf.erb'),
      owner   =>  root,
      group   =>  root,
      mode    =>  '0644',
      require =>  Package['httpd'],
    }
    
    file  { '/var/www/html/clamav':
      ensure  =>  directory,
      owner   =>  $clamuser,
      group   =>  $clamuser,
      mode    =>  '2755',
      require =>  [Package['httpd'],Package['clamav']],
    }
    
    file  { '/etc/freshclam.conf':
      ensure  =>  file,
      content =>  template('common/clamav/server_freshclam_conf.erb'),
      owner   =>  root,
      group   =>  root,
      mode    =>  '0644',
      require =>  Package['clamav'],
    }
    
    file  { '/etc/cron.d/update-clamdb.sh':
      ensure  =>  file,
      content =>  template('common/clamav/server_update_clamdb_sh.erb'),
      owner   =>  root,
      group   =>  root,
      mode    =>  '0755',
      require =>  Package['clamav'],
    }
    
    cron  { 'update-clamdb':
      command =>  '/etc/cron.d/update-clamdb.sh',
      user    =>  root,
      hour    =>  '*/2',
      minute  =>  0,
      require =>  File['/etc/cron.d/update-clamdb.sh'],
    }

    service { 'httpd':
      ensure  =>  running,
      enable  =>  true,
      require =>  [Package['httpd'],Package['clamav']],
    }

    file  { "/var/spool/cron/${clamuser}":
      ensure  =>  absent,
      require =>  File['/etc/freshclam.conf'],
    }
}
