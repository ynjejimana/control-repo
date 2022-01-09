class puppet::client ($puppet_server, $version = installed, $dns_alt_names = [], $noclient = true, $yum_versionlock_packagename = "yum-plugin-versionlock") {

	define line($file, $line, $ensure = 'present') {
		case $ensure {
			default : { err ( "unknown ensure value ${ensure}" ) }
			present: {
				exec { "/bin/echo '${line}' >> '${file}'":
					unless => "/bin/grep -qFx '${line}' '${file}'"
				}
			}
			absent: {
				exec { "/usr/bin/perl -ni -e 'print unless /^\\Q${line}\\E\$/' '${file}'":
					onlyif => "/bin/grep -qFx '${line}' '${file}'"
				}
			}
		}
	}

	case $::operatingsystem {
		"CentOS": {
			include repos::centos::puppetlabs
		}
		default: { }
	}

	$install_version = $::osfamily ? {
		"RedHat" => "${version}-1.el${::operatingsystemmajrelease}",
		default => $version,
	}

	package {"puppet":
		ensure => $install_version,
	}

	if $::osfamily == "RedHat" {
		package { $yum_versionlock_packagename:
			ensure => installed,
		}

		if $::operatingsystemmajrelease == "5" {
			line { "puppet_versionlock":
				file	=> "/etc/yum/pluginconf.d/versionlock.list",
				line	=> "0:puppet-${install_version}.",
			}
			line { "puppet-server_versionlock":
				file	=> "/etc/yum/pluginconf.d/versionlock.list",
				line	=> "0:puppet-server-${install_version}.",
			}
		} else {
			exec { "remove-puppet-versionlock":
				command => "yum versionlock delete puppet*",
				path    => "/usr/bin:/usr/sbin:/bin:/usr/local/bin:/sbin",
				onlyif  => "yum versionlock list | grep puppet && ! rpm -qa | grep puppet-${install_version}",
				before  => Package["puppet"],
				require => Package[$yum_versionlock_packagename],
			}

			exec { "add-puppet-versionlock":
				command => "yum versionlock add puppet",
				path    => "/usr/bin:/usr/sbin:/bin:/usr/local/bin:/sbin",
				onlyif  => "rpm -qa | grep puppet-${install_version} && ! yum versionlock list | grep puppet",
				require => [ Package["puppet"], Package[$yum_versionlock_packagename] ],
			}
		}
	}

	File {
		owner => puppet,
		group => puppet,
		mode => "0644",
		ensure => file,
	}

	file { "/etc/sysconfig/puppet":
		content => template("puppet/sysconfig.erb"),
		owner   => root,
		group   => root,
	}

	file {"/etc/puppet/auth.conf":
		content => template("puppet/auth.conf.erb"),
	}
	
	file {"/etc/puppet/puppet.conf":
		content => template("puppet/client_puppet.conf.erb"),
	}
}
