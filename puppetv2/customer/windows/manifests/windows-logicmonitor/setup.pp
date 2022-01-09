class windows::windows-logicmonitor::setup (
  $lmmanaged	= 'false',
  $username	= 'svc_logicmonitor',
  $aclpath	= 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Perflib',
) {

  if $lmmanaged == 'true' {
    case $domainjoined {
      'true':	{ $upn = "${username}@${domain}"}
      default:	{ $upn = "${hostname}\\${username}"}
    }

    file { 'lm_reg_acl.ps1':
        path    =>  'c:\windows\temp\lm_reg_acl.ps1',
        content => template('windows/windows-logicmonitor/lm_reg_acl.ps1.erb'),
        notify	=> Exec['EnablePerfmon_logicmonitor'],
    }

    file { 'lm_wmi_acl.ps1':
        path    =>  'c:\windows\temp\lm_wmi_acl.ps1',
        content => template('windows/windows-logicmonitor/lm_wmi_acl.ps1.erb'),
        notify	=> Exec['EnableWMI_logicmonitor'],
    }

    exec { 'EnablePerfmon_logicmonitor':
      path         => 'c:\windows\temp',
      cwd          => 'c:\windows\temp',
      command      => '& c:\windows\temp\lm_reg_acl.ps1',
      provider     => powershell,
      require      => File['lm_reg_acl.ps1'],
      refreshonly  => true,
    }

    exec { 'EnableWMI_logicmonitor':
      path         => 'c:\windows\temp',
      cwd          => 'c:\windows\temp',
      command      => '& c:\windows\temp\lm_wmi_acl.ps1',
      provider     => powershell,
      require      => File['lm_wmi_acl.ps1'],
      refreshonly  => true,
    }
  }
}