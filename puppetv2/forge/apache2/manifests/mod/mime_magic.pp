class apache2::mod::mime_magic (
  $magic_file = undef,
) {
  include ::apache2
  $_magic_file = pick($magic_file, "${::apache2::conf_dir}/magic")
  apache2::mod { 'mime_magic': }
  # Template uses $magic_file
  file { 'mime_magic.conf':
    ensure  => file,
    path    => "${::apache2::mod_dir}/mime_magic.conf",
    mode    => $::apache2::file_mode,
    content => template('apache2/mod/mime_magic.conf.erb'),
    require => Exec["mkdir ${::apache2::mod_dir}"],
    before  => File[$::apache2::mod_dir],
    notify  => Class['apache2::service'],
  }
}
