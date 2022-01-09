# Class: tuned::profile::enable_profile
#
# Parameters:
#
class tuned::profile::enable_profile (
    $profile_name   = $::tuned::profile_name,
    $tuned_conf_dir = $::tuned::tuned_conf_dir,
    $tuned_pkg      = $::tuned::tuned_pkg,
) {

    exec { "tuned-adm_enable_profile_${profile_name}":
        command => "tuned-adm profile ${profile_name}",
        path    => '/usr/bin:/usr/sbin/:/bin:/sbin:/usr/local/bin:/usr/local/sbin',
        unless  => "grep -q -e '^${profile_name}\$' ${tuned_conf_dir}/active_profile",
        require => Package[$tuned_pkg],
    }

}
