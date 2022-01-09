class apache2::mod::ext_filter(
  $ext_filter_define = undef
) {
  include ::apache2
  if $ext_filter_define {
    validate_hash($ext_filter_define)
  }

  ::apache2::mod { 'ext_filter': }

  # Template uses
  # -$ext_filter_define

  if $ext_filter_define {
    file { 'ext_filter.conf':
      ensure  => file,
      path    => "${::apache2::mod_dir}/ext_filter.conf",
      mode    => $::apache2::file_mode,
      content => template('apache2/mod/ext_filter.conf.erb'),
      require => [ Exec["mkdir ${::apache2::mod_dir}"], ],
      before  => File[$::apache2::mod_dir],
      notify  => Class['Apache2::Service'],
    }
  }
}
