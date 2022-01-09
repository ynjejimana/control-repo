class windows::windows-timezone::config (
  $timezone = hiera('windows::windows-timezone::config::timezone','AUS Eastern Standard Time'),
  $enabletimezone = hiera('windows::windows-timezone::config::enabletimezone',true)
) {

  unless $enabletimezone == false {

    exec { 'timezone':
      command  => "c:\\windows\\system32\\tzutil.exe /s \"${timezone}\"",
      onlyif   => "if ( [system.timezone]::currenttimezone.standardname -eq \"${timezone}\" ) { exit 1 }",
      provider => powershell,
    }

  }

}
