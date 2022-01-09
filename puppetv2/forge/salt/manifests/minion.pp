class salt::minion($salt_master = "puppet.esbu.lab.com.au" ) {
  if $::operatingsystem == "CentOS" {
    package { 'salt-minion':
      ensure => installed,
    }

    service { 'salt-minion':
      enable  => true,
      ensure  => running,
      require => File["/etc/salt/minion"],
    }

    file { '/etc/salt/minion':
      ensure  => file,
      content => template("salt/minion.erb"),
      notify  => Service["salt-minion"],
      require => Package["salt-minion"],
    }
  }
}