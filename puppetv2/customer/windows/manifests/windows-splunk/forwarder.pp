class windows::windows-splunk::forwarder ( $installersource,$username,$password,$deployment_server,$deployment_port,$ntrightssource )  {

$installsplunk = hiera('windows::windows-splunk::forwarder::installsplunk','false')
$tempsource = 'c:\build'
$serviceaccountperms = hiera('windows::windows-splunk::forwarder::serviceaccountsperms','true')
$lowprivilegemode = hiera('windows::windows-splunk::forwarder::lowprivilegemode','0')

if $installsplunk == 'true' {

  if $serviceaccountperms == 'true' {
  
    exec { 'CopySource' :
      path        =>  'C:\windows\system32',
      command     =>  "(md $tempsource) -and (cp ${ntrightssource} $tempsource)",
      onlyif      =>  "if ((test-path ${tempsource}\\ntrights.exe) -eq \$true) { exit 1}",
      provider    =>  powershell,
      before      =>  Exec['ApplyPermissions'],
      notify      =>  Exec['ApplyPermissions'],
      }
  
    exec { 'ApplyPermissions' :
      path        =>  $tempsource,
      cwd         =>  $tempsource,
      command     =>  "${tempsource}\\ntrights.exe -u ${username} +r SeServiceLogonRight && ${tempsource}\\ntrights.exe -u ${username} +r SeBatchLogonRight && ${tempsource}\\ntrights.exe -u ${username} +r SeCreateTokenPrivilege && ${tempsource}\\ntrights.exe -u ${username} +r SeTcbPrivilege && ${tempsource}\\ntrights.exe -u ${username} +r SeChangeNotifyPrivilege",
      provider    => windows,
      before      => Package["UniversalForwarder"],
      refreshonly => true,
      }
    }
  
    package {"UniversalForwarder":
      source                     => "${installersource}",
      ensure                     => installed,
      provider                   => windows,
      install_options            => {
        "AGREETOLICENSE"         => 'Yes',
        "LAUNCHSPLUNK"           => "1",
        "LOGON_USERNAME"         => "${username}",
        "LOGON_PASSWORD"         => "${password}",
        "DEPLOYMENT_SERVER"      => "${deployment_server}:${deployment_port}",
        "SERVICESTARTTYPE"       => "auto",
        "SET_ADMIN_USER"         => "${lowprivilegemode}",
      logoutput                  => on_failure,
      },
    }
  }
}
