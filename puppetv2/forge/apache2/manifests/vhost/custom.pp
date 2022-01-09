# See README.md for usage information
define apache2::vhost::custom(
  $content,
  $ensure = 'present',
  $priority = '25',
  $verify_config = true,
) {
  include ::apache

  ## Apache include does not always work with spaces in the filename
  $filename = regsubst($name, ' ', '_', 'G')

  ::apache2::custom_config { $filename:
    ensure        => $ensure,
    confdir       => $::apache2::vhost_dir,
    content       => $content,
    priority      => $priority,
    verify_config => $verify_config,
  }

  # NOTE(pabelanger): This code is duplicated in ::apache2::vhost and needs to
  # converted into something generic.
  if $::apache2::vhost_enable_dir {
    $vhost_symlink_ensure = $ensure ? {
      present => link,
      default => $ensure,
    }

    file { "${priority}-${filename}.conf symlink":
      ensure  => $vhost_symlink_ensure,
      path    => "${::apache2::vhost_enable_dir}/${priority}-${filename}.conf",
      target  => "${::apache2::vhost_dir}/${priority}-${filename}.conf",
      owner   => 'root',
      group   => $::apache2::params::root_group,
      mode    => $::apache2::file_mode,
      require => Apache2::Custom_config[$filename],
    }
  }
}
