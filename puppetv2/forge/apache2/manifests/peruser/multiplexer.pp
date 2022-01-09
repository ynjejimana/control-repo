define apache2::peruser::multiplexer (
  $user = $::apache2::user,
  $group = $::apache2::group,
  $file = undef,
) {
  if ! $file {
    $filename = "${name}.conf"
  } else {
    $filename = $file
  }
  file { "${::apache2::mod_dir}/peruser/multiplexers/${filename}":
    ensure  => file,
    content => "Multiplexer ${user} ${group}\n",
    require => File["${::apache2::mod_dir}/peruser/multiplexers"],
    notify  => Class['apache2::service'],
  }
}
