class windows::windows-wmiperms::setup (
  $managewmiperms = 'false',
  $username	= 'svc_snowdisco',
  $wmi_namespaces = {},
) {

  if $managewmiperms == 'true' {

    case $domainjoined {
      'true':	{ $upn = "${username}@${domain}"}
      default:	{ $upn = "${hostname}\\${username}"}
    }

    file { 'wmi_acls.ps1':
        path    =>  'c:\windows\temp\wmi_acls.ps1',
        content => template('windows/windows-wmiperms/wmi_acls.ps1.erb'),
        notify	=> Exec['EnableWMI'],
    }

    exec { 'EnableWMI':
      path      => 'c:\windows\temp',
      cwd       => 'c:\windows\temp',
      command   => '& c:\windows\temp\wmi_acls.ps1',
      provider  => powershell,
      require   => File['wmi_acls.ps1'],
      refreshonly  => true,
    }
  }
}
