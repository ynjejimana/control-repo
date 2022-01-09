class common::validation::build {

$packages = [
    "perl-LDAP",
    "perl-Net-DNS",
  ]

package { $packages:
  ensure => installed,
  }

file { '/tmp/build':
  ensure  => file,
  source  => "puppet:///modules/common/validation",
  recurse => true,
  }

  exec { "script-prerequisite-untar" :
   cwd     => "/tmp",
   command => "/bin/tar -xvf /tmp/build/checkScriptPrereqs.tar",
   creates => "/tmp/TARs",
   require => File['/tmp/build'],
   before  => [
   	Exec['perl-Net-SMTP_auth'],
	 	Exec['perl-Net-Server-Mail'],
	 	Exec['Test-SMTP-0.04'],
   	Exec['Net-NTP-1.3'],
   	Exec['Test-Simple-0.98'],
   	Exec['Test-Pod-Coverage-1.08'],
   	Exec['Test-Pod-1.45'],
   	Exec['Test-Exception-0.31'],
   	Exec['Sub-Uplevel-0.24'],
   	Exec['Socket6-0.23'],
   	Exec['Pod-Simple-3.22'],
   	Exec['Pod-Escapes-1.04'],
   	Exec['Pod-Coverage-0.22'],
   	Exec['Net-Server-Mail-ESMTP-AUTH-0.1'],
   	Exec['IO-Socket-INET6-2.69'],
   	Exec['ExtUtils-MakeMaker-6.62'],
   	Exec['ExtUtils-CBuilder-0.280205'],
   	Exec['Devel-Symdump-2.08'],
   	Exec['Config-Simple-4.59'],
   	Exec['Authen-SASL-2.15'],
	 ],
  }

 exec { "perl-Net-SMTP_auth" :
  cwd     => "/tmp",
  command => "/bin/tar -xvf /tmp/TARs/Net-SMTP_auth-0.08.tar.gz && cd /tmp/Net-SMTP_auth-0.08 && /usr/bin/perl Makefile.PL && make && make install",
  creates => "/tmp/Net-SMTP_auth-0.08",
  require => Exec['script-prerequisite-untar'],
}

  exec { "perl-Net-Server-Mail" :
  cwd     => "/tmp",
  command => "/bin/tar -xvf /tmp/TARs/Net-Server-Mail-0.18.tar.gz && cd /tmp/Net-Server-Mail-0.18 && /usr/bin/perl Makefile.PL && make && make install",
  creates => "/tmp/Net-Server-Mail-0.18",
  require => Exec['script-prerequisite-untar'],
}

exec { "Test-SMTP-0.04" :
  cwd     => "/tmp",
  command => "/bin/tar -xvf /tmp/TARs/Test-SMTP-0.04.tar.gz && cd /tmp/Test-SMTP-0.04 && /usr/bin/perl Makefile.PL && make && make install",
  creates => "/tmp/Test-SMTP-0.04",
  require => Exec['script-prerequisite-untar'],
}

exec { "Net-NTP-1.3" :
  cwd     => "/tmp",
  command => "/bin/tar -xvf /tmp/TARs/Net-NTP-1.3.tar.gz && cd /tmp/Net-NTP-1.3 && /usr/bin/perl Makefile.PL && make && make install",
  creates => "/tmp/Net-NTP-1.3",
  require => Exec['script-prerequisite-untar'],
}

exec { "Test-Simple-0.98" :
  cwd     => "/tmp",
  command => "/bin/tar -xvf /tmp/TARs/Test-Simple-0.98.tar.gz && cd /tmp/Test-Simple-0.98 && /usr/bin/perl Makefile.PL && make && make install",
  creates => "/tmp/Test-Simple-0.98",
  require => Exec['script-prerequisite-untar'],
}

exec { "Test-Pod-Coverage-1.08" :
  cwd     => "/tmp",
  command => "/bin/tar -xvf /tmp/TARs/Test-Pod-Coverage-1.08.tar.gz && cd /tmp/Test-Pod-Coverage-1.08 && /usr/bin/perl Makefile.PL && make && make install",
  creates => "/tmp/Test-Pod-Coverage-1.08",
  require => Exec['script-prerequisite-untar'],
}

exec { "Test-Pod-1.45" :
  cwd     => "/tmp",
  command => "/bin/tar -xvf /tmp/TARs/Test-Pod-1.45.tar.gz && cd /tmp/Test-Pod-1.45 && /usr/bin/perl Makefile.PL && make && make install",
  creates => "/tmp/Test-Pod-1.45",
  require => Exec['script-prerequisite-untar'],
}

exec { "Test-Exception-0.31" :
  cwd     => "/tmp",
  command => "/bin/tar -xvf /tmp/TARs/Test-Exception-0.31.tar.gz && cd /tmp/Test-Exception-0.31 && /usr/bin/perl Makefile.PL && make && make install",
  creates => "/tmp/Test-Exception-0.31",
  require => Exec['script-prerequisite-untar'],
}

exec { "Sub-Uplevel-0.24" :
  cwd     => "/tmp",
  command => "/bin/tar -xvf /tmp/TARs/Sub-Uplevel-0.24.tar.gz && cd /tmp/Sub-Uplevel-0.24 && /usr/bin/perl Makefile.PL && make && make install",
  creates => "/tmp/Sub-Uplevel-0.24",
  require => Exec['script-prerequisite-untar'],
}

exec { "Socket6-0.23" :
  cwd     => "/tmp",
  command => "/bin/tar -xvf /tmp/TARs/Socket6-0.23.tar.gz && cd /tmp/Socket6-0.23 && /usr/bin/perl Makefile.PL && make && make install",
  creates => "/tmp/Socket6-0.23",
  require => Exec['script-prerequisite-untar'],
}

exec { "Pod-Simple-3.22" :
  cwd     => "/tmp",
  command => "/bin/tar -xvf /tmp/TARs/Pod-Simple-3.22.tar.gz && cd /tmp/Pod-Simple-3.22 && /usr/bin/perl Makefile.PL && make && make install",
  creates => "/tmp/Pod-Simple-3.22",
  require => Exec['script-prerequisite-untar'],
}

exec { "Pod-Escapes-1.04" :
  cwd     => "/tmp",
  command => "/bin/tar -xvf /tmp/TARs/Pod-Escapes-1.04.tar.gz && cd /tmp/Pod-Escapes-1.04 && /usr/bin/perl Makefile.PL && make && make install",
  creates => "/tmp/Pod-Escapes-1.04",
  require => Exec['script-prerequisite-untar'],
}

exec { "Pod-Coverage-0.22" :
  cwd     => "/tmp",
  command => "/bin/tar -xvf /tmp/TARs/Pod-Coverage-0.22.tar.gz && cd /tmp/Pod-Coverage-0.22 && /usr/bin/perl Makefile.PL && make && make install",
  creates => "/tmp/Pod-Coverage-0.22",
  require => Exec['script-prerequisite-untar'],
}

exec { "Net-Server-Mail-ESMTP-AUTH-0.1" :
  cwd     => "/tmp",
  command => "/bin/tar -xvf /tmp/TARs/Net-Server-Mail-ESMTP-AUTH-0.1.tar.gz && cd /tmp/Net-Server-Mail-ESMTP-AUTH-0.1 && /usr/bin/perl Makefile.PL && make && make install",
  creates => "/tmp/Net-Server-Mail-ESMTP-AUTH-0.1",
  require => Exec['script-prerequisite-untar'],
}

exec { "IO-Socket-INET6-2.69" :
  cwd     => "/tmp",
  command => "/bin/tar -xvf /tmp/TARs/IO-Socket-INET6-2.69.tar.gz && cd /tmp/IO-Socket-INET6-2.69 && /usr/bin/perl Makefile.PL && make && make install",
  creates => "/tmp/IO-Socket-INET6-2.69",
  require => Exec['script-prerequisite-untar'],
}

exec { "ExtUtils-MakeMaker-6.62" :
  cwd     => "/tmp",
  command => "/bin/tar -xvf /tmp/TARs/ExtUtils-MakeMaker-6.62.tar.gz && cd /tmp/ExtUtils-MakeMaker-6.62 && /usr/bin/perl Makefile.PL && make && make install",
  creates => "/tmp/ExtUtils-MakeMaker-6.62",
  require => Exec['script-prerequisite-untar'],
}

exec { "ExtUtils-CBuilder-0.280205" :
  cwd     => "/tmp",
  command => "/bin/tar -xvf /tmp/TARs/ExtUtils-CBuilder-0.280205.tar.gz && cd /tmp/ExtUtils-CBuilder-0.280205 && /usr/bin/perl Makefile.PL && make && make install",
  creates => "/tmp/ExtUtils-CBuilder-0.280205",
  require => Exec['script-prerequisite-untar'],
}

exec { "Devel-Symdump-2.08" :
  cwd     => "/tmp",
  command => "/bin/tar -xvf /tmp/TARs/Devel-Symdump-2.08.tar.gz && cd /tmp/Devel-Symdump-2.08 && /usr/bin/perl Makefile.PL && make && make install",
  creates => "/tmp/Devel-Symdump-2.08",
  require => Exec['script-prerequisite-untar'],
}

exec { "Config-Simple-4.59" :
  cwd     => "/tmp",
  command => "/bin/tar -xvf /tmp/TARs/Config-Simple-4.59.tar.gz && cd /tmp/Config-Simple-4.59 && /usr/bin/perl Makefile.PL && make && make install",
  creates => "/tmp/Config-Simple-4.59",
  require => Exec['script-prerequisite-untar'],
}

exec { "Authen-SASL-2.15" :
  cwd     => "/tmp",
  command => "/bin/tar -xvf /tmp/TARs/Authen-SASL-2.15.tar.gz && cd /tmp/Authen-SASL-2.15 && /usr/bin/perl Makefile.PL && make && make install",
  creates => "/tmp/Authen-SASL-2.15",
  require => Exec['script-prerequisite-untar'],
}

file {"/tmp/build/${hostname}.ini":
  content => template("common/validation/capnrlab.ini.erb"),
  require => File["/tmp/build"],
  before  => Exec['validate'],
}

exec { "validate":
	cwd     => "/tmp/build",
	command => "/usr/bin/perl runtest.pl ${hostname}.ini",
  onlyif => "/usr/bin/test ! -e /tmp/build/serverbuild-${hostname}-*",
	require => Exec['Authen-SASL-2.15'],
}

}

