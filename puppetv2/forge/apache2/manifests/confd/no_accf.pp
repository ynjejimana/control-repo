class apache2::confd::no_accf {
  # Template uses no variables
  file { 'no-accf.conf':
    ensure  => 'file',
    path    => "${::apache2::confd_dir}/no-accf.conf",
    content => template('apache2/confd/no-accf.conf.erb'),
    require => Exec["mkdir ${::apache2::confd_dir}"],
    before  => File[$::apache2::confd_dir],
  }
}
