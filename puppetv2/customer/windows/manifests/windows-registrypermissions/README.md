
RegistryPermissions
========

This class configures Access Control Lists for Windows OS registry keys.


Usage
--------

**aclpath**: Full path to the registry key.

**inheritance**: Inheritance flags for Access Control Entries (ACEs). Available flags combinations are:  
*"ContainerInherit"*, *"ObjectInherit"*, *"ContainerInherit, ObjectInherit"*, *"None"*

**propagation**: Propagation Flags specify how Access Control Entries (ACEs) are propagated to child objects. Available flags are:  
*"InheritOnly"*, *"None"*.

 **Inheritance/Propagation** combinations:

 - **Key only:**
   - Propagation: None
   - Inheritance: None
 - **Key, sub-keys and values:**
   - Propagation: None
   - Inheritance: ContainerInherit,ObjectInherit
 - **Key and sub-keys:**
   - Propagation: None
   - Inheritance: ContainerInherit
 - **Key and Values:**
   - Propagation: None
   - Inheritance: ObjectInherit
 - **Sub-keys and Values:**
   - Propagation: InheritOnly
   - Inheritance: ContainerInherit,ObjectInherit
 - **Sub-keys:**
   - Propagation: InheritOnly
   - Inheritance: ContainerInherit
 - **Values:**
   - Propagation: InheritOnly
   - Inheritance: ObjectInherit

**accessRights**: access control rights to be applied to the registry object. Available rights are:  
*"ChangePermissions"*, *"CreateSubKey"*, *"Delete"*,*"EnumerateSubKeys"*, *"FullControl"*, *"QueryValues"*, *"ReadKey"*, *"ReadPermissions"*, *"SetValue"*, *"TakeOwnership"*, *"WriteKey"*

**accessType**: specify whether an AccessRule object is used to allow or deny access. Available flags are:  
*"Allow"*, *"Deny"*


Example:
--------

windows::windows-registrypermissions::setup::manageregistrypermissions: 'true'  
windows::windows-registrypermissions::setup::registryPermissions:  
&nbsp;WindowsCurrentVersion:  
&nbsp;&nbsp;aclpath: 'HKLM:\Software\Microsoft\Windows\CurrentVersion'  
&nbsp;&nbsp;account: 'testdomain\regtest'  
&nbsp;&nbsp;inheritance: 'ContainerInherit, ObjectInherit'  
&nbsp;&nbsp;propagation: 'None'  
&nbsp;&nbsp;accessRights: 'FullControl'  
&nbsp;&nbsp;accessType: 'Allow'  
&nbsp;Mozilla:  
&nbsp;&nbsp;aclpath: 'HKLM:\Software\Mozilla'  
&nbsp;&nbsp;account: 'testdomain\regtest'  
&nbsp;&nbsp;inheritance: 'ContainerInherit, ObjectInherit'  
&nbsp;&nbsp;propagation: 'None'  
&nbsp;&nbsp;accessRights: 'ReadKey'  
&nbsp;&nbsp;accessType: 'Allow'  

