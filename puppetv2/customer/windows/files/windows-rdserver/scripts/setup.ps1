start-transcript -path c:\windows\setup\scripts\rdserver\install.log -append
$features = "RDS-WEB-ACCESS","RDS-RD-SERVER", "RDS-Connection-Broker", "RSAT-RDS-Tools", "RDS-Gateway"
$fqdn=[System.Net.DNS]::GetHostByName('').HostName
$collectionname="RDServer"
#$usergroup="`"$env:userdomain\Domain Users`""
$maxsessiontime="1200"
$idlesessiontime="600"
$discsessiontime="1200"

#Install RDS roles ( Connection Broker, Session Host, Web Access, Services Tools )

$windowsfeatures=get-windowsfeature

foreach ( $feature in $features ) {
        if ( ($windowsfeatures | where { $_.name -eq $feature }).installstate -ne "Installed") {
                install-windowsfeature -name $feature -includeallsubfeature -restart
                }
        }

#Process reboot after role installation
if  ( (test-path "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") -eq $true) { shutdown /r /f /c "Restarting as part of RDServer setup" }

#Configure RD services
<#
import-module remotedesktop

# Due to restart requirements, the RDS roles need to be installed prior to this commandlet as this script is run on the target server.
# This commandlet will solely be used for initial configuration
New-RDSessionDeployment -ConnectionBroker $fqdn -WebAccessServer $fqdn -SessionHost $fqdn

# Build new collection
New-RDSessionCollection -collectionname $collectionname -sessionhost $fqdn

#Configure collection
Set-RDSessionCollectionConfiguration -collectionname $collectionname -ActiveSessionLimitMin $maxsessiontime -UserGroup $Usergroup -IdleSessionLimitMin $idletime -DisconnectedSessionLimitMin $DiscSessionTime

#set RD Terminal server licensing
if ( $licenseserver -ne $null ) {
Set-RDLicenseConfiguration -LicenseServer $licenseserver -Mode PerUser -ConnectionBroker $fqdn
}
#>
stop-transcript
