class esbu::rt::install ($relayhost = undef, $smtp_listen = $::ipaddress, $fallback_relay = undef, $no_transport = false ) {

$rtpackages = ["procmail",'postfix']
  package{ $rtpackages:
    ensure => present,
  }

  
## postfix config ##

#class { 'postfix':
#    smtp_listen => $smtp_listen,
#  }

file { '/etc/postfix/main.cf':
  ensure  => 'present',
  source  => "puppet:///modules/esbu/rt/main.cf",
  require => Package['postfix'],
}

service { 'postfix':
  ensure    => running,
  subscribe => File['/etc/postfix/main.cf']
}

## user config ##

  user { 'helpdesk':
    ensure     => 'present',
    comment    => 'Helpdesk/RT User',
    shell      => '/bin/bash',
    managehome => true,
 }

  file {'/home/helpdesk/.procmailrc':
    ensure  => 'present',
    source  => "puppet:///modules/esbu/rt/procmailrc",
    owner   => 'helpdesk',
    require => User['helpdesk'],
  }

## mail stripper ###

  file {'/usr/bin/stripper':
    ensure => 'present',
    source => "puppet:///modules/esbu/rt/stripper",
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  }

##  iptables firewall ##
#  service {'iptables':
#    ensure => 'running',
#    subscribe => File['/etc/sysconfig/iptables'],
#  }

#  file {'/etc/sysconfig/iptables':
#    ensure => present,
#    source => "puppet:///modules/esbu/rt/iptables",
   
#}

## attachment folder ##

  file {[ "/srv","/srv/attachments" ]:
    ensure  => directory,
    owner   => 'helpdesk',
    require => User['helpdesk'],
}

  file {'/attachments':
    ensure  => 'link',
    target  => '/srv/attachments',
    require => File['/srv/attachments'],
  }


## apache config ####

class { "apache":
    default_vhost    => false,
    server_tokens    => 'ProductOnly',
    trace_enable     => 'off',
    timeout          => '60',
    serveradmin      => 'root@localhost',
    server_signature => 'Off',
    }

  apache::listen { '80': }

apache::vhost { 'rt.harbour':
  docroot       => '/var/www/rt',
  serveraliases => 'rt',
  options       => ['Indexes','FollowSymLinks'],
  }

apache::vhost {'rtattach.harbour':
  docroot       => '/attachments',
  options       => ['Indexes','FollowSymLinks'],
  override      => "All",
  serveraliases => 'rtattach',
}

apache::vhost {'rtattach.esbu.lab.com.au':
  docroot       => '/attachments',
  options       => ['Indexes','FollowSymLinks'],
  override      => "All",
  serveraliases => 'rtattach.esbu.lab.com.au',
}

}
