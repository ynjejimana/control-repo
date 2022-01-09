class apache2::mod::mime (
  $mime_support_package = $::apache2::params::mime_support_package,
  $mime_types_config    = $::apache2::params::mime_types_config,
  $mime_types_additional = undef,
) inherits ::apache2::params {
  include ::apache2
  $_mime_types_additional = pick($mime_types_additional, $apache2::mime_types_additional)
  apache2::mod { 'mime': }
  # Template uses $_mime_types_config
  file { 'mime.conf':
    ensure  => file,
    path    => "${::apache2::mod_dir}/mime.conf",
    mode    => $::apache2::file_mode,
    content => template('apache2/mod/mime.conf.erb'),
    require => Exec["mkdir ${::apache2::mod_dir}"],
    before  => File[$::apache2::mod_dir],
    notify  => Class['apache2::service'],
  }
  if $mime_support_package {
    package { $mime_support_package:
      ensure => 'installed',
      before => File['mime.conf'],
    }
  }
}
