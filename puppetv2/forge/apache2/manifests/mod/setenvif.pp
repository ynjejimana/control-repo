class apache2::mod::setenvif {
  ::apache2::mod { 'setenvif': }
  # Template uses no variables
  file { 'setenvif.conf':
    ensure  => file,
    path    => "${::apache2::mod_dir}/setenvif.conf",
    mode    => $::apache2::file_mode,
    content => template('apache2/mod/setenvif.conf.erb'),
    require => Exec["mkdir ${::apache2::mod_dir}"],
    before  => File[$::apache2::mod_dir],
    notify  => Class['apache2::service'],
  }
}
