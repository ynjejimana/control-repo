class apache2::mod::autoindex {
  ::apache2::mod { 'autoindex': }
  # Template uses no variables
  file { 'autoindex.conf':
    ensure  => file,
    path    => "${::apache2::mod_dir}/autoindex.conf",
    mode    => $::apache2::file_mode,
    content => template('apache2/mod/autoindex.conf.erb'),
    require => Exec["mkdir ${::apache2::mod_dir}"],
    before  => File[$::apache2::mod_dir],
    notify  => Class['apache2::service'],
  }
}
