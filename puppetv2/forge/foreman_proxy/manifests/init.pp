class foreman_proxy (
	$bmc = false,						# Configure bmc on this proxy?
	$chef = false,						# Configure chef on this proxy?
	$dhcp = false,						# Configure DHCP on this proxy?
	$dhcp_provider = undef,					# If dhcp == true, which DHCP provider?
	$dhcp_leases_file = undef,				# If dhcp_provider == dhcp_isc, where is the leases file?
	$dhcp_config_file = undef,				# If dhcp_provider == dhcp_isc, where is the config file?
	$discovery = false,					# Configure bare metal discovery on this proxy?
	$dns = false,						# Configure DNS on this proxy?
	$dns_provider = undef,					# If dns == true, which DNS provider?
	$dns_server = undef,					# If dns == true, which DNS server?
	$dns_tsig_key_name = undef,				# If dns_provider == dns_nsupdate, what is the name of the RNDC key?
	$dns_tsig_key_data = undef,				# If dns_provider == dns_nsupdate, what is the data in the RNDC key?
	$dns_tsig_keytab = undef,				# If dns_provider == dns_nsupdate_gss, where is the file containing the keytab of the service account that manipulates DNS?
	$dns_tsig_principal = undef,				# If dns_provider == dns_nsupdate_gss, what is the name of the principal of the service account that manipulates DNS?
	$facts = false,						# Configure facts on this proxy?
	$logs = false,						# Configure logs on this proxy?
	$puppetca = false,					# Configure puppet CA on this proxy?
	$puppet = false,					# Configure puppet server on this proxy?
	$puppet_provider = undef,				# If puppet == true, which puppet provider (i.e. method of running puppet on puppet clients)?
	$puppet_version = undef,				# If puppet == true, which version of puppet?
	$realm = false,						# Configure realm on this proxy?
	$realm_principal = undef,				# If realm == true, what is the principal of the service account that manipulates realms?
	$templates = false,					# Configure templates on this proxy?
	$tftp = false,						# Configure TFTP on this proxy?
) {

	# gwaugh, 10/01/2017: Commenting out the below, because:
	#  * We don't want to use manually-configured yum repos pointing to our repo servers, as we have Spacewalk/Satellite channels containing the Foreman packages.
	#  * We don't want everything owned by 'foreman-proxy:foreman-proxy' as the daemon runs as this user, so breaking in through the service remotely will mean any
	#      file managed by this puppet class will be able to be modified. Instead, leave the file ownership as per the RPM specification (root-owned).
	#  * It is not necessary to manage the '/etc/foreman' directory in this class.
	#  * It is not necessary to manage the '/usr/share/foreman-proxy/bin/smart-proxy' file in this class.

	##case $::operatingsystem {
	##	'CentOS': {
	##		include repos::centos::foreman
	##		include repos::centos::foreman_plugins
	##	}
	##	default: { }
	##}

	##File {
	##	owner => 'foreman-proxy',
	##	group => 'foreman-proxy',
	##}

	##if !defined(File['/etc/foreman']) {
	##	file { '/etc/foreman':
	##		ensure => directory,
	##	}
	##}

	##file { '/usr/share/foreman-proxy/bin/smart-proxy':
	##	ensure  => file,
	##	owner   => 'foreman-proxy',
	##	group   => 'foreman-proxy',
	##	mode    => '0755',
	##	require => Package['foreman-proxy'],
	##}

	package { 'foreman-proxy':
		ensure => installed,
                install_options => ['--nogpgcheck']
	}

	user { 'foreman-proxy':
		ensure  => present,
		groups  => 'puppet',
		require => Package['foreman-proxy'],
	}

	# gwaugh, 10/01/2017: Not sure if these directories need to be managed, but it seems relatively benign so I'll leave it here for the moment
	file { ['/var/lib/foreman-proxy', '/var/run/foreman-proxy']:
		ensure  => directory,
		owner   => 'foreman-proxy',
		group   => 'foreman-proxy',
		mode	=> '0755',
		require => Package['foreman-proxy'],
	}

	# The main foreman-proxy settings file
	file { '/etc/foreman-proxy/settings.yml':
		ensure  => file,
		owner   => 'root',
		group   => 'foreman-proxy',
		mode	=> '0640',
		content => template('foreman_proxy/settings.yml.erb'),
		require => Package['foreman-proxy'],
		notify  => Service['foreman-proxy'],
	}

	if $dns == true {
		case $dns_provider {
			"dns_nsupdate": {
				file { '/etc/foreman-proxy/rndc.key':
					ensure  => file,
					owner   => 'root',
					group   => 'foreman-proxy',
					mode	=> '0640',
					content => template('foreman_proxy/rndc.key.erb'),
					notify  => Service['foreman-proxy'],
				}
			}
			# If using dns_update_gss, define this file, which should contain the kerberos keytab of the service account used to manipulate DNS entries
		 	"dns_update_gss": {
				file { '/etc/foreman-proxy/dns.keytab':
					ensure  => file,
					owner   => 'root',
					group   => 'foreman-proxy',
					mode	=> '0640',
					notify  => Service['foreman-proxy'],
				}
			}
			# Add more $dns_providers if and when they are required
		}
	}

	service { 'foreman-proxy':
		enable  => true,
		ensure  => running,
		require => [ File['/etc/foreman-proxy/settings.yml'], Package['foreman-proxy'] ],
	}

	# bmc -- Baseboard Management Controller (e.g. iLO, DRAC etc.)
	if $bmc == true {
		package { 'ipmitool':
			ensure => installed,
		}
	}

	# puppetca -- the puppet Certificate Authority component
	if $puppetca == true {
		include ::sudo
		::sudo::conf { 'foreman-proxy' :
			ensure  => present,
			content => "foreman-proxy ALL = NOPASSWD : /usr/bin/puppet cert *, /usr/bin/puppet kick *\nDefaults:foreman-proxy !requiretty",
		}
	}

	# Manage the '/etc/foreman-proxy/settings.d' directory recursively, purging unmanaged files, with 'root' ownership and 'foreman-proxy' group,
	# mode 0640 for files and 0750 for directories
	file { '/etc/foreman-proxy/settings.d':
		ensure  => directory,
		owner   => 'root',
		group   => 'foreman-proxy',
		mode	=> 'u+rw,g+r,o-rwx',
		recurse	=> true,
		purge	=> true,
		require => Package['foreman-proxy'],
	}

	# Here follows the configuration files for the various components
	file { '/etc/foreman-proxy/settings.d/bmc.yml':
		ensure  => file,
		owner	=> 'root',
		group   => 'foreman-proxy',
		mode	=> '0640',
		content => template('foreman_proxy/settings.bmc.yml.erb'),
		notify  => Service['foreman-proxy'],
	}

	file { '/etc/foreman-proxy/settings.d/chef.yml':
		ensure  => file,
		owner	=> 'root',
		group   => 'foreman-proxy',
		mode	=> '0640',
		content => template('foreman_proxy/settings.chef.yml.erb'),
		notify  => Service['foreman-proxy'],
	}

	file { '/etc/foreman-proxy/settings.d/dhcp_isc.yml':
		ensure  => file,
		owner	=> 'root',
		group   => 'foreman-proxy',
		mode	=> '0640',
		content => template('foreman_proxy/settings.dhcp_isc.yml.erb'),
		notify  => Service['foreman-proxy'],
	}

	file { '/etc/foreman-proxy/settings.d/dhcp_libvirt.yml':
		ensure  => file,
		owner	=> 'root',
		group   => 'foreman-proxy',
		mode	=> '0640',
		content => template('foreman_proxy/settings.dhcp_libvirt.yml.erb'),
		notify  => Service['foreman-proxy'],
	}

	file { '/etc/foreman-proxy/settings.d/dhcp_native_ms.yml':
		ensure  => file,
		owner	=> 'root',
		group   => 'foreman-proxy',
		mode	=> '0640',
		content => template('foreman_proxy/settings.dhcp_native_ms.yml.erb'),
		notify  => Service['foreman-proxy'],
	}

	file { '/etc/foreman-proxy/settings.d/dhcp.yml':
		ensure  => file,
		owner	=> 'root',
		group   => 'foreman-proxy',
		mode	=> '0640',
		content => template('foreman_proxy/settings.dhcp.yml.erb'),
		notify  => Service['foreman-proxy'],
	}

	if $discovery == true {
		package { 'rubygem-smart_proxy_discovery':
			ensure => installed,
                        install_options => ['--nogpgcheck']
		}
		file { '/etc/foreman-proxy/settings.d/discovery.yml':
			ensure	=> file,
			owner   => 'root',
			group   => 'foreman-proxy',
			mode	=> '0640',
			content	=> template('foreman_proxy/settings.discovery.yml.erb'),
			notify	=> Service['foreman-proxy'],
			require	=> Package['rubygem-smart_proxy_discovery'],
		}
	}

	file { '/etc/foreman-proxy/settings.d/dns_dnscmd.yml':
		ensure  => file,
		owner	=> 'root',
		group   => 'foreman-proxy',
		mode	=> '0640',
		content => template('foreman_proxy/settings.dns_dnscmd.yml.erb'),
		notify  => Service['foreman-proxy'],
	}

	file { '/etc/foreman-proxy/settings.d/dns_libvirt.yml':
		ensure  => file,
		owner	=> 'root',
		group   => 'foreman-proxy',
		mode	=> '0640',
		content => template('foreman_proxy/settings.dns_libvirt.yml.erb'),
		notify  => Service['foreman-proxy'],
	}

	file { '/etc/foreman-proxy/settings.d/dns_nsupdate.yml':
		ensure  => file,
		owner	=> 'root',
		group   => 'foreman-proxy',
		mode	=> '0640',
		content => template('foreman_proxy/settings.dns_nsupdate.yml.erb'),
		notify  => Service['foreman-proxy'],
	}

	file { '/etc/foreman-proxy/settings.d/dns_nsupdate_gss.yml':
		ensure  => file,
		owner	=> 'root',
		group   => 'foreman-proxy',
		mode	=> '0640',
		content => template('foreman_proxy/settings.dns_nsupdate_gss.yml.erb'),
		notify  => Service['foreman-proxy'],
	}

	file { '/etc/foreman-proxy/settings.d/dns.yml':
		ensure  => file,
		owner	=> 'root',
		group   => 'foreman-proxy',
		mode	=> '0640',
		content => template('foreman_proxy/settings.dns.yml.erb'),
		notify  => Service['foreman-proxy'],
	}

	file { '/etc/foreman-proxy/settings.d/facts.yml':
		ensure  => file,
		owner	=> 'root',
		group   => 'foreman-proxy',
		mode	=> '0640',
		content => template('foreman_proxy/settings.facts.yml.erb'),
		notify  => Service['foreman-proxy'],
	}

	file { '/etc/foreman-proxy/settings.d/logs.yml':
		ensure  => file,
		owner	=> 'root',
		group   => 'foreman-proxy',
		mode	=> '0640',
		content => template('foreman_proxy/settings.logs.yml.erb'),
		notify  => Service['foreman-proxy'],
	}

	file { '/etc/foreman-proxy/settings.d/puppetca.yml':
		ensure  => file,
		owner	=> 'root',
		group   => 'foreman-proxy',
		mode	=> '0640',
		content => template('foreman_proxy/settings.puppetca.yml.erb'),
		notify  => Service['foreman-proxy'],
	}

	file { '/etc/foreman-proxy/settings.d/puppet_proxy_salt.yml':
		ensure  => file,
		owner	=> 'root',
		group   => 'foreman-proxy',
		mode	=> '0640',
		content => template('foreman_proxy/settings.puppet_proxy_salt.yml.erb'),
		notify  => Service['foreman-proxy'],
	}

	file { '/etc/foreman-proxy/settings.d/puppet.yml':
		ensure  => file,
		owner	=> 'root',
		group   => 'foreman-proxy',
		mode	=> '0640',
		content => template('foreman_proxy/settings.puppet.yml.erb'),
		notify  => Service['foreman-proxy'],
	}

	file { '/etc/foreman-proxy/settings.d/realm.yml':
		ensure  => file,
		owner	=> 'root',
		group   => 'foreman-proxy',
		mode	=> '0640',
		content => template('foreman_proxy/settings.realm.yml.erb'),
		notify  => Service['foreman-proxy'],
	}

	file { '/etc/foreman-proxy/settings.d/templates.yml':
		ensure  => file,
		owner	=> 'root',
		group   => 'foreman-proxy',
		mode	=> '0640',
		content => template('foreman_proxy/settings.templates.yml.erb'),
		notify  => Service['foreman-proxy'],
	}

	file { '/etc/foreman-proxy/settings.d/tftp.yml':
		ensure  => file,
		owner	=> 'root',
		group   => 'foreman-proxy',
		mode	=> '0640',
		content => template('foreman_proxy/settings.tftp.yml.erb'),
		notify  => Service['foreman-proxy'],
	}
}
