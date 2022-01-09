
LocalGroups
========

This class configures Local Groups for Windows OS.


Usage
--------

**group**: Full name of the local group.

**accounts**: coma-separated user accounts (username); both local and domain accounts can be provided. 


Example:
--------

windows::windows-localgroups::setup::managelocalgroups: 'true'
windows::windows-localgroups::setup::groups:
&nbsp;RDUsers:  
&nbsp;&nbsp;group: 'Remote Desktop Users'
&nbsp;&nbsp;accounts: 'domain\rduser1,rduser2@domain.local,localuser1' 
&nbsp;PowerUsers:  
&nbsp;&nbsp;group: 'Power Users'
&nbsp;&nbsp;accounts: 'domain\rduser2,rduser3@domain.local,localuser2' 