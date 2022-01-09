# Define: tuned::profile::create_script
#
# Parameters:
#
define tuned::profile::create_script (
    $ensure      = 'file',
    $script_name = $title,
    $scripts     = undef,
    $profile_dir = undef,
) {

    validate_string($script_name)

    $script_content = $scripts[$script_name]

    file { "${profile_dir}/${script_name}":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        content => $script_content,
    }
}
