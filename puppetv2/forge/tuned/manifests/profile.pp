# Define: tuned::profile
#
# This define permit the definition of a new tuned profile
#
# Parameters:
#
# [*ensure*]
#   String. Ensure if present of absent
#   Default: 'present'
#   Valid values: present, absent
#
# [*profile_name*]
#   String. The profile name
#   Default: $title
#
# [*conf_content*]
#   String. Content of tuned profile
#   Default: undef
#
# [*scripts*]
#   String. Scripts used by tuned profile
#   Default: {}
#
define tuned::profile (
    $ensure         = 'present',
    $profile_name   = $title,
    $tuned_conf_dir = $::tuned::tuned_conf_dir,
    $tuned_pkg      = $::tuned::tuned_pkg,
    $conf_content   = undef,
    $scripts        = {},
) {

    if ! defined(Class['tuned']) {
        fail('You must include the tuned base class before define a tuned profile')
    }

    validate_string($conf_content)
    validate_hash($scripts)

    case $ensure {
        'present': {
            $dir_ensure  = 'directory'
            $file_ensure = 'file'
        }
        'absent': {
            $dir_ensure  = 'absent'
            $file_ensure = 'absent'
        }
        default: {
            fail("${ensure} is not supported for ensure.")
        }
    }

    $profile_dir = "${tuned_conf_dir}/${profile_name}"

    file { $profile_dir:
        ensure  => $dir_ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        purge   => true,
        recurse => true,
        force   => true,
        require => Package[$tuned_pkg],
        before  => Class['tuned::profile::enable_profile'],
    }->
    file { "${profile_dir}/tuned.conf":
        ensure  => $file_ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => $conf_content,
        before  => Class['tuned::profile::enable_profile'],
    }

    $script_names = keys($scripts)
    if size($script_names) > 0 {
        tuned::profile::create_script { $script_names:
            ensure      => $file_ensure,
            scripts     => $scripts,
            profile_dir => $profile_dir,
            require     => File[$profile_dir],
            before      => Class['tuned::profile::enable_profile'],
        }
    }

}
