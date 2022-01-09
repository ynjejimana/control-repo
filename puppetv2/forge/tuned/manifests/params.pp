# == Class: tuned::params
#
# This class manages tuned parameters
#
#
class tuned::params {

    if (versioncmp($::operatingsystemmajrelease, '7') >= 0){
        $tuned_services = ['tuned']
        $tuned_conf_dir = '/etc/tuned'
    } else {
        $tuned_services = ['tuned', 'ktune']
        $tuned_conf_dir = '/etc/tune-profiles'
    }

    $tuned_pkg      = 'tuned'
    $active_profile = undef

    case $::osfamily {
        'RedHat': {}
        default: {
            fail("Unsupported platform: ${::osfamily}/${::operatingsystem}")
        }
    }
}
