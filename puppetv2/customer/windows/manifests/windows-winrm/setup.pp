class windows::windows-winrm::setup {

$setupwinrm = hiera('windows::window-winrm::setup::setupwinrm','True')

  if $setupwinrm == 'True' {

     file { "winrm_scripts":
       path               =>  'C:/windows/setup/scripts/winrm',
       ensure             =>  directory,
       recurse            =>  remote,
       source             =>  "puppet:///modules/windows/windows-winrm/scripts",
       source_permissions =>  ignore,
       }

     exec { "ManageCertificate":              
       command            =>  '& C:/windows/setup/scripts/winrm/DeleteHTTPSListener.ps1',
       onlyif             =>  '& C:/windows/setup/scripts/winrm/CheckCert.ps1',
       logoutput          =>  true,
       provider           =>  powershell,
       require            =>  File['winrm_scripts'],
       } ~>

     exec { "SetupWinRM":
       command            =>  '& C:/windows/setup/scripts/winrm/ConfigureRemotingForAnsible.ps1',
       onlyif             =>  'if ((Get-ChildItem WSMan:\localhost\Listener | Where {$_.Keys -like "TRANSPORT=HTTPS"}) -ne $null) {exit 1}',
       logoutput          =>  true,
       provider           =>  powershell,
       require            =>  File['winrm_scripts'],
       }

  }
}
