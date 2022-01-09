class salt::master ($order_masters = false, $syndic_master = "globfrmn01.esbu.lab.com.au" ) {
	if $::operatingsystem == "CentOS" {
	  package { ['salt-master', 'salt-syndic']:
	    ensure => installed,
	  }

	  service { ['salt-master', 'salt-syndic']:
	    enable  => true,
	    ensure  => running,
	    require => File["/etc/salt/master"],
	  }

	  file { '/etc/salt/master':
	    ensure  => file,
	    content => template("salt/master.erb"),
	    notify  => [ Service['salt-master'], Service['salt-syndic'] ],
	    require => Package["salt-master"],
	  }
	}
}
