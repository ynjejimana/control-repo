class apache2::mod::expires (
  $expires_active  = true,
  $expires_default = undef,
  $expires_by_type = undef,
) {
  include ::apache2
  ::apache2::mod { 'expires': }

  # Template uses
  # $expires_active
  # $expires_default
  # $expires_by_type
  file { 'expires.conf':
    ensure  => file,
    path    => "${::apache2::mod_dir}/expires.conf",
    mode    => $::apache2::file_mode,
    content => template('apache2/mod/expires.conf.erb'),
    require => Exec["mkdir ${::apache2::mod_dir}"],
    before  => File[$::apache2::mod_dir],
    notify  => Class['apache2::service'],
  }
}
