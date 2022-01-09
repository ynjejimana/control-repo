# Class: tuned
#
# This class manages tuned.
#
# Parameters:
#
# [*tuned_ensure*]
#   String. Ensure if present of absent
#   Default: 'present'
#   Valid values: present, absent
#
# [*service_ensure*]
#   String. Ensure if running or stopped
#   Default: 'running'
#   Valid values: running, stopped
#
# [*active_profile*]
#   String. Tuned profile that must be enable
#   Default: undef
#
class tuned (
    $tuned_ensure   = 'present',
    $service_ensure = 'running',
    $tuned_services = $::tuned::params::tuned_services,
    $tuned_conf_dir = $::tuned::params::tuned_conf_dir,
    $tuned_pkg      = $::tuned::params::tuned_pkg,
    $active_profile = $::tuned::params::active_profile,
) inherits tuned::params {

    validate_re($tuned_ensure, '^(present|absent)$', "${tuned_ensure} is not supported for tuned_ensure.")
    validate_re($service_ensure, '^(running|stopped)$', "${service_ensure} is not supported for service_ensure.")

    package { $tuned_pkg:
        ensure => $tuned_ensure,
    }

    service { $tuned_services:
        ensure    => $service_ensure,
        enable    => true,
        hasstatus => true,
        require   => Package[$tuned_pkg],
    }

    file { "${tuned_conf_dir}/bootcmdline":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('tuned/bootcmdline.erb'),
        require => Package[$tuned_pkg],
        notify  => Service[$tuned_services],
    }

    file { "${tuned_conf_dir}/tuned-main.conf":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('tuned/tuned-main.conf.erb'),
        require => Package[$tuned_pkg],
        notify  => Service[$tuned_services],
    }

    if $active_profile {
        class {'::tuned::profile::enable_profile':
            profile_name => $active_profile,
            require      => Package[$tuned_pkg],
        }
    }

}
