class common::ipa::client (
	$servers		= "",
	$domain 		= "",
	$realm 			= "",
	$principle		= "",
	$ntp			= false,
	$password		= "Welcome123",
	$package		= "ipa-client",
	$fixed_primary		= true,
) {

	# removed this as I dont think its needed anymore as ipa-client is in the default repos assigned via spacewalk registration
  #if $::osfamily == "RedHat" and $::operatingsystemmajrelease == "7" {
	#	require repos::centos::freeipa
	#}
	if $domain == '' {
		fail('A $domain value is required.')
	}
	
	if $servers == '' {
		fail('A $servers value is required.')
	}
	#if "${realm}" != '' {
        #   realm           => $realm,
	#}


	if $::osfamily == "RedHat" and $::operatingsystemmajrelease == "7" {
		package { "initscripts":
			ensure => installed,
			before => Class['::ipaclient'],
		}
	
		# We are managing this file in order to work around, https://git.fedorahosted.org/cgit/initscripts.git/commit/?h=rhel7-branch&id=3deb3b3c177dd24b22cf912cd798aeaa7e35d30b
		file { '/usr/lib/systemd/system/rhel-domainname.service':
			ensure  => present,
			source  => "puppet:///modules/common/ipa/client/rhel-domainname.service",
			owner   => root,
			group   => root,
			mode    => '0644',
			require => Package['initscripts'],
			
		}
	}

	if defined(Class["common::ntp::client"]) {
	  class { '::ipaclient':
	    principal		=> $principle,
            password		=> $password,
            domain		=> $domain,
	    server		=> fqdn_rotate($servers),
	    realm		=> $realm,
            mkhomedir		=> true,
            automount		=> false,
            ssh			=> true,
	    fixed_primary	=> $fixed_primary,
	    package		=> $package,
	    ntp			=> $ntp,
	    # accenture machines use shorthostnames, this option allows them to register regardless
	    # passed as an array otherwise it tries to quote the option incorrectly and fails to parse on the cmdline
	    options		=> ["--hostname", $::fqdn],
	    require		=> Service['ntpd'],
	  }
	} else {
	  class { '::ipaclient':
	    principal		=> $principle,
            password		=> $password,
            domain		=> $domain,
	    server		=> fqdn_rotate($servers),
	    realm		=> $realm,
            mkhomedir		=> true,
            automount		=> false,
            ssh			=> true,
	    fixed_primary	=> $fixed_primary,
	    package		=> $package,
	    ntp			=> $ntp,
	    # accenture machines use shorthostnames, this option allows them to register regardless
	    # passed as an array otherwise it tries to quote the option incorrectly and fails to parse on the cmdline
	    options		=> ["--hostname", $::fqdn],
	  }
	}

}
