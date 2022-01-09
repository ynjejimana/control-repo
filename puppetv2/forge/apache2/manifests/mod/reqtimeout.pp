class apache2::mod::reqtimeout (
  $timeouts = ['header=20-40,minrate=500', 'body=10,minrate=500']
){
  include ::apache2
  ::apache2::mod { 'reqtimeout': }
  # Template uses no variables
  file { 'reqtimeout.conf':
    ensure  => file,
    path    => "${::apache2::mod_dir}/reqtimeout.conf",
    content => template('apache2/mod/reqtimeout.conf.erb'),
    require => Exec["mkdir ${::apache2::mod_dir}"],
    before  => File[$::apache2::mod_dir],
    notify  => Class['apache2::service'],
  }
}
