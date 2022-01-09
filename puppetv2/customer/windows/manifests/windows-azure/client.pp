class windows::windows-azure::client (
  $azureagent_enabled       = 'true',
) {

if $::osfamily == 'Windows' {
  if $azureagent_enabled == 'true' {
     service { 'WinGA':
                ensure   => 'running',
                enabled  => true,
             }
  } else {
     service { 'WinGA':
                ensure   => 'stopped',
                enabled  => false,
             }
  }
 }
}
