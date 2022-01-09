class windows::windows-ntp::windowsclient (
  $server_list = hiera('windows::windows-ntp::windowsclient::server_list','["172.16.40.146","172.16.40.147"]'),
  $enablentp = hiera('windows::windows-ntp::windowsclient::enablentp',true)
)  {

  if $enablentp == true {

    $endbit = ',0x8'
    $tmpNTPServers = join($server_list, ',0x8 ')
    $sNTPServers = "${tmpNTPServers}${endbit}"

    service { 'W32time':
      ensure => 'running',
      enable => true,
      notify => Exec[resyncNTP],
      before =>  Class['windows-networking::dnsclients'],
    }

    exec { 'resyncNTP':
      path        => 'C:/Windows/System32',
      command     => 'w32tm /resync',
      refreshonly => true,
    }

    if $::domainrole != 'Primary Domain Controller' or $::domainrole != 'Backup Domain Controller' {

      if ($::domainrole == 'Standalone Server') {
        registry::value { 'NTPServer':
          key    => 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\w32time\Parameters',
          value  => 'NtpServer',
          data   => $sNTPServers,
          notify => Service['W32time'],
        }

        registry::value { 'NTPtype':
          key    => 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\w32time\Parameters',
          value  => 'Type',
          data   => 'NTP',
          notify => Service['W32time'],
        }
      } else {

        registry::value { 'DomainNTP':
          key    => 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\w32time\Parameters',
          value  => 'Type',
          data   => 'NT5DS',
          notify => Service['W32time'],
        }
      }
    }
  }
}
