class windows::windows-registrypermissions::setup (
  $manageregistrypermissions = 'false',
  $registryPermissions	     = {},
) {

  if $manageregistrypermissions == 'true' {

    file { 'registry_permissions.ps1':
      path    => "${systemdrive}\\windows\\temp\\registry_permissions.ps1",
      content => template('windows/windows-registrypermissions/registry_permissions.erb'),
      notify  => Exec['Set_registrypermissions'],
    }

    exec { 'Set_registrypermissions':
      path         => "${systemdrive}\\windows\\temp",
      cwd          => "${systemdrive}\\windows\\temp",
      command      => "& ${systemdrive}\\windows\\temp\\registry_permissions.ps1",
      provider     => powershell,
      require      => File['registry_permissions.ps1'],
      refreshonly  => true,
    }
  }
}