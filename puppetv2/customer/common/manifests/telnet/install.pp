class common::telnet::install {
  tag "autoupdate"
	
  if !defined(Package["telnet"]) {
    package { ["telnet"] :
        ensure => installed,
    }
  }


  if  $::osfamily == 'RedHat' and $::operatingsystemmajrelease == '7' {
  	$nc = "nmap-ncat"
  }
  else {
  	$nc = 'nc'
  }

  if !defined(Package["nc"]) {
    	package { "nc" :
        	ensure => installed,
		name          => $nc,
    	}
  }
}
