define apache2::peruser::processor (
  $user,
  $group,
  $file = undef,
) {
  if ! $file {
    $filename = "${name}.conf"
  } else {
    $filename = $file
  }
  file { "${::apache2::mod_dir}/peruser/processors/${filename}":
    ensure  => file,
    content => "Processor ${user} ${group}\n",
    require => File["${::apache2::mod_dir}/peruser/processors"],
    notify  => Class['apache2::service'],
  }
}
