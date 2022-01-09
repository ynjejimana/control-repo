class windows::windows-rdserver::setup {

    file { "RDS_installscripts":
         path               =>  'C:/windows/setup/scripts/rdserver',
         ensure             =>  directory,
         recurse            =>  remote,
         source             =>  "puppet:///modules/windows/windows-rdserver/scripts",
         source_permissions =>  ignore,
         require            =>  Class['windows::windows-domainjoin::join'],
         }

    exec { "SetupRDS":
         path      =>  'C:/windows/setup/scripts/rdserver',
         cwd       =>  'C:/windows/setup/scripts/rdserver',
         command   =>  '& C:/windows/setup/scripts/rdserver/setup.ps1',
         onlyif    =>  'test.ps1',
         logoutput =>  true,
         provider  =>  powershell,
         require   =>  File['RDS_installscripts'],
         }
}

