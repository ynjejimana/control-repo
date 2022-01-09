
WMIPermissions
========

This class configures Access Control Lists for Windows OS WMI namespaces.


Usage
--------

**namespace**: Full path to the WMI namespace (e.g. "root\cimv2").

**account**: Either Local or Active Directory account to be provided with WMI access

**permissions**: A coma-separated list of WMI permissions to be provided. Available permissions are:  
*"EnableAccount"*, *"ExecuteMethods"*, *"FullWrite"*, *"PartialWrite"*, *"ProviderWrite"*, *"RemoteEnable"*, *"ReadSecurity"*, *"EditSecurity"*.


Example:
--------

windows::windows-wmipermissions::setup::managewmipermissions: 'true'  
windows::windows-wmipermissions::setup::wmiPermissions:  
&nbsp;cimv2:  
&nbsp;&nbsp;namespace: 'root\cimv2'  
&nbsp;&nbsp;account: 'testdomain\wmitest'  
&nbsp;&nbsp;permissions: 'EnableAccount,RemoteEnable'  
&nbsp;default:  
&nbsp;&nbsp;namespace: 'root\DEFAULT'  
&nbsp;&nbsp;account: 'wmitest@testdomain.local'  
&nbsp;&nbsp;permissions: 'EnableAccount,RemoteEnable,FullWrite'  
