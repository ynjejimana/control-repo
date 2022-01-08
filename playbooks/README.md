Ansible Patching
=====
### Overview

This set of playbooks is designed to be a complete solution for updating Linux hosts.

### Requirements

To be able to use this playbook you need to ensure that the following python libraries:

* pyvmomi
* jmespath

These can be installed using pip

        pip install pyvmomi
        pip install jmespath

### Process

##### VMWare Guest patching

###### Automated
1. Take snapshots with __vmware_snapshot.yml__;
2. Run __site.yml__ which will go ahead and run all of the playbooks in order.
        ## Group of Hosts
        ansible-playbook -i Inventories/production/hosts.ini site.yml -k -u root --limit=<group_name>
 
        ## Single Host
        ansible-playbook -i Inventories/production/hosts.ini site.yml -k -u root --limit=<name_of_host>

###### Staged
1. Take snapshots with __vmware_snapshot.yml__;
2. Run the __pre_patch_checks.yml__ which will check for things like diskspace etc;
        ## Group of Hosts
        ansible-playbook -i Inventories/production/hosts.ini pre_patch_checks.yml -k -u root --limit=<group_name>
        
        ## Single Host
        ansible-playbook -i Inventories/production/hosts.ini pre_patch_checks.yml -k -u root --limit<name_of_host>
3. If that comes back ok then run __patching.yml__ which will disable puppet/crond and apply all the updates applicable to the system;
        ## Group of Hosts
        ansible-playbook -i Inventories/production/hosts.ini patching.yml -k -u root --limit=<group_name>
        
        ## Single Host
        ansible-playbook -i Inventories/production/hosts.ini patching.yml -k -u root --limit<name_of_host>
4. Then once that has been applied and the system is ready to be restarted then run __reboot.yml__ which will reboot the system, wait for it to become available and then re-enable puppet/crond.
        ## Group of Hosts
        ansible-playbook -i Inventories/production/hosts.ini reboot.yml -k -u root --limit=<group_name>
        
        ## Single Host
        ansible-playbook -i Inventories/production/hosts.ini reboot.yml -k -u root --limit<name_of_host>

#### Other patching

###### Automated
1. Ensure backups have been taken and are current;
2. Run __site.yml__ which will run all of the playbooks in order.
        ## Group of Hosts
        ansible-playbook -i Inventories/production/hosts.ini site.yml -k -u root --limit=<group_name>
 
        ## Single Host
        ansible-playbook -i Inventories/production/hosts.ini site.yml -k -u root --limit=<name_of_host>

###### Staged
1. Ensure backups have been taken and are current;
2. Run __pre_patch_checks.yml__;
        ## Group of Hosts
        ansible-playbook -i Inventories/production/hosts.ini pre_patch_checks.yml -k -u root --limit=<group_name>
        
        ## Single Host
        ansible-playbook -i Inventories/production/hosts.ini pre_patch_checks.yml -k -u root --limit<name_of_host>
3. Run __patching.yml__;
        ## Group of Hosts
        ansible-playbook -i Inventories/production/hosts.ini patching.yml -k -u root --limit=<group_name>
        
        ## Single Host
        ansible-playbook -i Inventories/production/hosts.ini patching.yml -k -u root --limit<name_of_host>
4. Run __reboot.yml__.
        ## Group of Hosts
        ansible-playbook -i Inventories/production/hosts.ini reboot.yml -k -u root --limit=<group_name>
        
        ## Single Host
        ansible-playbook -i Inventories/production/hosts.ini reboot.yml -k -u root --limit<name_of_host>

#### NJeJI **DEPRECATED**

###### Automated
Other patching steps can be followed.

###### Staged
1. Ensure backups have been taken and are current;
2. Run __pre_patch_checks.yml__;
3. Run __njeji_pre_tasks.yml__ this has njeji exclusive tasks which includes removal of the DCS agent depending on the group the host is in;
4. Run __patching.yml__;
5. Run __reboot.yml__;
6. Run __njeji_post_tasks.yml__ this will undo what we did in __njeji_pre_tasks.yml__;

### To Do
There are still multiple things that need to be added a list can be found [here](Docs/TODO.md).

### Contributing

[Contributing Guide](Docs/CONTRIBUTING.md).

### Author

Yves Njejimana
