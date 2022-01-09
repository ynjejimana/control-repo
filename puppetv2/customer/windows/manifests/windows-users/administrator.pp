class windows::windows-users::administrator {

$managed = hiera('windows::windows-users::administrator::managed','false')
$adminname = hiera('windows::windows-users::administrator::adminname','esbuadmin')
$accountdisabled = hiera('windows::windows-users::administrator::accountdisabled','false')
$password = hiera('windows::windows-users::administrator::password')
$manage_password = hiera('windows::windows-users::administrator::manage_password',true)

if $managed == 'true' {

  if $::domainrole == 'Standalone Server' or $::domainrole == 'Member Server' {

    exec { "renameAdministrator":
        command  =>  "(Get-WMIObject Win32_UserAccount -Filter \"Name=\'administrator\'\").rename(\'${adminname}\')",
        onlyif   =>  'if ((Get-WMIObject Win32_UserAccount -Filter "Name=\'administrator\'") -eq $null) { exit 1}',
        path     =>  'C:\windows\system32',
        provider =>  powershell,
    }

    if $manage_password == true {
        user { $adminname:
            password   =>  $password,
            require => Exec['renameAdministrator'],
        }
    }
  }

  if $::domainrole == 'Member Server' and $accountdisabled == 'true' {

    exec { "DisableAccount":
       command   =>  "Get-WMIObject Win32_UserAccount -Filter \"domain='${::hostname}' and name='${adminname}'\" | %{ \$_.disabled=\$true;\$_.put()}",
       onlyif    =>  "if ((Get-WMIObject Win32_UserAccount -Filter \"domain='${::hostname}' and name='${adminname}'\").disabled -eq \$true) {exit 1}",
       path      =>  'C:\windows\system32',
       provider  =>  powershell,
       logoutput =>  true,
       }
  }

  else {

    exec { "EnableAccount":
       command   =>  "Get-WMIObject Win32_UserAccount -Filter \"domain='${::hostname}' and name='${adminname}'\" | %{ \$_.disabled=\$false;\$_.put()}",
       onlyif    =>  "if ((Get-WMIObject Win32_UserAccount -Filter \"domain='${::hostname}' and name='${adminname}'\").disabled -eq \$false) {exit 1}",
       path      =>  'C:\windows\system32',
       provider  =>  powershell,
       logoutput =>  true,
       }
  }
 }
}
