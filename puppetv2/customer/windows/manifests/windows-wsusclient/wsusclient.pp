class windows::windows-wsusclient::wsusclient ( 
  $serverurl		= undef,
  $wsusmanaged		= 'false',
  $auoptions		= '0x00000003',
  $targetgroup		= 'none',
) {

  if $wsusmanaged == 'true' {

    registry::value { 'WUServer':
      key	=> 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate',
      type	=> string,
      data	=> $serverurl,
      notify	=> Exec['Restart WSUS agent'],
    }

    registry::value { 'WUStatusServer':
      key	=> 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate',
      type	=> string,
      data	=> $serverurl,
      notify	=> Exec['Restart WSUS agent'],
    }

    registry::value { 'UseWUServer':
      key	=> 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU',
      type	=> dword,
      data	=> 0x00000001,
      notify	=> Exec['Restart WSUS agent'],
    }

    registry::value { 'AUOptions':
      key	=> 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU',
      type	=> dword,
      data	=> $auoptions,
      notify	=> Exec['Restart WSUS agent'],
    }

    if $targetgroup != 'none' {
      registry::value { 'TargetGroupEnabled':
        key	=> 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate',
        type	=> dword,
        data	=> 0x00000001,
        notify	=> Exec['Restart WSUS agent'],
      }

      registry::value { 'TargetGroup':
        key	=> 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate',
        type	=> string,
        data	=> $targetgroup,
        notify	=> Exec['Restart WSUS agent'],
      }
    }

    exec { 'Restart WSUS agent':
      command	   => "cmd.exe /c net stop wuauserv && net start wuauserv && wuauclt.exe /resetauthorization /detectnow",
      path	   => $::path,
      refreshonly  => true,
      onlyif	   => 'sc query wuauserv | find "RUNNING"',
    }

  }
}