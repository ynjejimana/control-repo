class windows::windows-rdp::enable {

  registry_value { 'HKLM:\System\CurrentControlSet\Control\Terminal Server\fDenyTSConnections':
    ensure => present,
    type   => dword,
    data   => "0",
  }
}
