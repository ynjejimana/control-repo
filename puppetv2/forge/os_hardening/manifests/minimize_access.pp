# === Copyright
#
# Copyright 2014, Deutsche Telekom AG
# Licensed under the Apache License, Version 2.0 (the "License");
# http://www.apache.org/licenses/LICENSE-2.0
#

# == Class: os_hardening::minimize_access
#
# Configures profile.conf.
#
class os_hardening::minimize_access (
  $allow_change_user = false,
){
  # from which folders to remove public access
  if $::osfamily == 'RedHat' and $::operatingsystemmajrelease == '7' {
  	$folders = [
    		'/usr/local/sbin',
    		'/usr/local/bin',
    		'/usr/sbin',
    		'/usr/bin',
  	]
  } else {
  	$folders = [
    		'/usr/local/sbin',
    		'/usr/local/bin',
    		'/usr/sbin',
    		'/usr/bin',
    		'/sbin',
    		'/bin',
  	]
 }

  # remove write permissions from path folders ($PATH) for all regular users
  # this prevents changing any system-wide command from normal users
  file { $folders:
    ensure  => 'directory',
    mode    => 'go-w',
    recurse => true,
  }
  # shadow must only be accessible to user root
  file { '/etc/shadow':
    owner => root,
    group => root,
    mode  => '0600',
  }

  # su must only be accessible to user and group root
  if $allow_change_user == true {
    file { '/bin/su':
      owner => root,
      group => root,
      mode  => '0750',
    }
  }

    file { '/tmp':
	    ensure	=> 'directory',
	    owner  => 'root',
	    group  => 'root',
	    mode   => '1777',
    }
    file { '/etc/group':
        mode => '0644',
    }
    file { '/etc/passwd':
        mode => '0644',
    }
    file { '/etc/gshadow':
        mode => '0400',
    }
    file { '/etc/inittab':
        mode  => '0600',
        owner => root,
        group => root,
    }
    file { '/etc/anacrontab':
        mode  => '0600',
        owner => root,
        group => root,
    }
    file { '/etc/crontab':
        mode  => '0600',
        owner => root,
        group => root,
    }
    file { '/etc/cron.d':
        mode  => '0700',
        owner => root,
        group => root,
    }
    file { '/etc/cron.hourly':
        mode  => '0700',
        owner => root,
        group => root,
    }
    file { '/etc/cron.daily':
        mode  => '0700',
        owner => root,
        group => root,
    }
    file { '/etc/cron.weekly':
        mode  => '0700',
        owner => root,
        group => root,
    }
    file { '/root':
        owner => 'root',
        group => 'root',
        mode  => '0700',
    }


}
