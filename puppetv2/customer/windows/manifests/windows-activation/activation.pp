class windows::windows-activation::activation (
  $KMSServer = '172.16.40.10',
  $enableactivation = true,
) {

  if $enableactivation == true {

  case $::edition {
    'Microsoft Windows Server 2016 Standard'       : {$KMSKey = 'WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY'}
    'Microsoft Windows Server 2016 Datacenter'     : {$KMSKey = 'CB7KF-BWN84-R7R2Y-793K2-8XDDG'}
    'Microsoft Windows Server 2012 R2 Standard'    : {$KMSKey = 'D2N9P-3P6X9-2R39C-7RTCD-MDVJX'}
    'Microsoft Windows Server 2012 R2 Datacenter'  : {$KMSKey = 'W3GGN-FT8W3-Y4M27-J84CP-Q3VJ9'}
    'Microsoft Windows Server 2008 R2 Standard'    : {$KMSKey = 'YC6KT-GKW9T-YTKYR-T4X34-R7VHC'}
    'Microsoft Windows Server 2008 R2 Enterprise'  : {$KMSKey = '489J6-VHDMP-X63PK-3K798-CPX3Y'}
  }

    exec { 'SetKMSKey':
        command  =>  "c:/windows/system32/cscript.exe c:/windows/system32/slmgr.vbs /ipk \"${KMSKey}\"",
        onlyif   =>  'if ((c:\windows\system32\cscript.exe c:/windows/system32/slmgr.vbs /dlv | select-string -pattern KMSCLIENT -quiet) -eq "$true") { exit 1 }',
        provider =>  powershell,
        before   =>  Exec['SetKMSServer'],
    }

    exec { 'SetKMSServer':
        command  =>  "c:/windows/system32/cscript.exe c:/windows/system32/slmgr.vbs /skms \"${KMSServer}\"",
        onlyif   =>  "if ( (c:/windows/system32/cscript.exe c:/windows/system32/slmgr.vbs /dlv | select-string -pattern \"${KMSServer}\" -quiet) -eq \"\$true\") { exit 1 }",
        provider =>  powershell,
        notify   =>  Exec['ActivateWindows']
    }

    exec { 'ActivateWindows':
        command     =>  'c:\windows\system32\cscript.exe c:\windows\system32\slmgr.vbs /ato',
        onlyif      =>  'if ((Get-WMIObject -Class SoftwareLicensingProduct |Where {$_.ApplicationID -eq "55c92734-d682-4d71-983e-d6ec3f16059f" -AND $_.PartialProductKey -ne $null}).licensestatus -eq "1") {exit 1}',
        provider    =>  powershell,
        refreshonly =>  true,
    }

  }

}
