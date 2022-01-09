class windows::windows-ad::dcpromo {

$dc = hiera('windows::windows-ad::dcpromo::dc')
$password = hiera('windows::windows-ad::dcpromo::password')
$username = hiera('windows::windows-ad::dcpromo::username')
$replicationsource = hiera('windows::windows-ad::dcpromo::replicationsource')
$sitename = hiera('windows::windows-ad::dcpromo::sitename')
$domainname = hiera('windows::windows-ad::dcpromo::domainname')

  if $::domainrole == 'Member Server' {

    file { 'C:\windows\setup\scripts\dcpromo.ps1':
            content =>  template('windows/windows-ad/dcpromo.ps1.erb'),
            path    =>  'C:\windows\setup\scripts\dcpromo.ps1',
            require =>  Class['windows-domainjoin::join'],
            }

    exec { 'dcpromo':
            path     =>  'C:\windows\setup\scripts',
            cwd      =>  'C:\windows\setup\scripts',
            command  =>  'dcpromo.ps1',
            onlyif   =>  "if ( \"${::domainrole}\" -eq \"Primary Domain Controller\" ) {exit 1}",
            require  =>  File['C:\windows\setup\scripts\dcpromo.ps1'],
            provider =>  powershell,
            notify   =>  Reboot['postinstall'],
            }

    reboot { 'postinstall':
            apply  =>  finished,
            notify =>  Exec['cleanup'],
            }

    exec { 'cleanup':
            path        =>  'C:\windows\setup\scripts',
            cwd         =>  'C:\windows\setup\scripts',
            command     =>  'remove-item C:\windows\setup\scripts\dcpromo.ps1',
            provider    =>  powershell,
            refreshonly =>  true,
            }
   }
}
