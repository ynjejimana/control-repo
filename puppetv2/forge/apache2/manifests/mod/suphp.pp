class apache2::mod::suphp (
){
  include ::apache2
  ::apache2::mod { 'suphp': }

  file {'suphp.conf':
    ensure  => file,
    path    => "${::apache2::mod_dir}/suphp.conf",
    mode    => $::apache2::file_mode,
    content => template('apache2/mod/suphp.conf.erb'),
    require => Exec["mkdir ${::apache2::mod_dir}"],
    before  => File[$::apache2::mod_dir],
    notify  => Class['apache2::service'],
  }
}

