class apache2::mod::alias(
  $apache_version = undef,
  $icons_options  = 'Indexes MultiViews',
  # set icons_path to false to disable the alias
  $icons_path     = $::apache2::params::alias_icons_path,
) inherits ::apache2::params {
  include ::apache2
  $_apache_version = pick($apache_version, $apache2::apache_version)
  apache2::mod { 'alias': }

  # Template uses $icons_path, $_apache_version
  if $icons_path {
    file { 'alias.conf':
      ensure  => file,
      path    => "${::apache2::mod_dir}/alias.conf",
      mode    => $::apache2::file_mode,
      content => template('apache2/mod/alias.conf.erb'),
      require => Exec["mkdir ${::apache2::mod_dir}"],
      before  => File[$::apache2::mod_dir],
      notify  => Class['apache2::service'],
    }
  }
}
