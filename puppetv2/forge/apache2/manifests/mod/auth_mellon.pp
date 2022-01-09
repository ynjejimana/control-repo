class apache2::mod::auth_mellon (
  $mellon_cache_size = $::apache2::params::mellon_cache_size,
  $mellon_lock_file  = $::apache2::params::mellon_lock_file,
  $mellon_post_directory = $::apache2::params::mellon_post_directory,
  $mellon_cache_entry_size = undef,
  $mellon_post_ttl = undef,
  $mellon_post_size = undef,
  $mellon_post_count = undef
) inherits ::apache2::params {

  include ::apache2
  ::apache2::mod { 'auth_mellon': }

  # Template uses
  # - All variables beginning with mellon_
  file { 'auth_mellon.conf':
    ensure  => file,
    path    => "${::apache2::mod_dir}/auth_mellon.conf",
    mode    => $::apache2::file_mode,
    content => template('apache2/mod/auth_mellon.conf.erb'),
    require => [ Exec["mkdir ${::apache2::mod_dir}"], ],
    before  => File[$::apache2::mod_dir],
    notify  => Class['Apache2::Service'],
  }

}
