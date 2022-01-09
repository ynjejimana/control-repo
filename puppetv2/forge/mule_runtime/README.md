# mule_runtime

A Puppet module to install Mule Runtime server.

## Usage

    node default {

      class  { 'java':
        distribution => 'jdk',
        version      => 'latest',
      }

      class  { 'mule_runtime':
        require => Class['java']
      }

    } 

## Dependencies 

Dependens on puppetlabs-java, puppet-archive puppet forge modules.

## Limitations

Unix system only support. RedHat (CentOS) tested.

## Release Notes/Contributors/Etc. **Optional**

3 Nov 2016 - Initial Release.
