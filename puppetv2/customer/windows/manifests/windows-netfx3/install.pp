class windows::windows-netfx3::install ($sxssource) {

     exec { 'CopySXSfiles':
         provider =>  powershell,
         command  =>  "copy-item ${sxssource} -recurse c:/sxssource",
         path     =>  'c:\windows\system32',
         cwd      =>  'c:\windows\system32',
         onlyif   =>  'if ((test-path c:\sxssource) -eq $true) {exit 1}',
         before   =>  Exec['NetFx3'],
         }

    exec { 'NetFx3' :
         provider =>  powershell,
         command  =>  'dism /online /enable-feature /featurename:NetFx3 /All /source:c:\sxssource',
         onlyif   =>  'if ((get-windowsfeature | where { $_.name -eq "Net-framework-core" }).installstate -eq "Installed") {exit 1}',
         path     =>  'c:\windows\system32',
         cwd      =>  'c:\windows\system32',
         }
}
