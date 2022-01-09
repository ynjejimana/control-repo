class windows::windows-wmipermissions::setup (
  $managewmipermissions = 'false',
  $wmiPermissions	= {},
) {

  if $managewmipermissions == 'true' {

    file { 'wmi_permissions.ps1':
        path    => "${systemdrive}\\windows\\temp\\wmi_permissions.ps1",
        content => template('windows/windows-wmipermissions/wmi_permissions.erb'),
        notify	=> Exec['Set_wmipermissions'],
    }

    exec { 'Set_wmipermissions':
      path         => "${systemdrive}\\windows\\temp",
      cwd          => "${systemdrive}\\windows\\temp",
      command      => "& ${systemdrive}\\windows\\temp\\wmi_permissions.ps1",
      provider     => powershell,
      require      => File['wmi_permissions.ps1'],
      refreshonly  => true,
    }
  }
}