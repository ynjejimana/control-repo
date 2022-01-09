class apache2::mod::info (
  $allow_from      = ['127.0.0.1','::1'],
  $apache_version  = undef,
  $restrict_access = true,
  $info_path       = '/server-info',
){
  include ::apache2
  $_apache_version = pick($apache_version, $apache2::apache_version)
  apache2::mod { 'info': }
  # Template uses $allow_from, $_apache_version
  file { 'info.conf':
    ensure  => file,
    path    => "${::apache2::mod_dir}/info.conf",
    mode    => $::apache2::file_mode,
    content => template('apache2/mod/info.conf.erb'),
    require => Exec["mkdir ${::apache2::mod_dir}"],
    before  => File[$::apache2::mod_dir],
    notify  => Class['apache2::service'],
  }
}
