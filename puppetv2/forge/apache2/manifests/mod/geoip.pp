class apache2::mod::geoip (
  $enable                     = false,
  $db_file                    = '/usr/share/GeoIP/GeoIP.dat',
  $flag                       = 'Standard',
  $output                     = 'All',
  $enable_utf8                = undef,
  $scan_proxy_headers         = undef,
  $scan_proxy_header_field    = undef,
  $use_last_xforwarededfor_ip = undef,
) {
  ::apache2::mod { 'geoip': }

  # Template uses:
  # - enable
  # - db_file
  # - flag
  # - output
  # - enable_utf8
  # - scan_proxy_headers
  # - scan_proxy_header_field
  # - use_last_xforwarededfor_ip
  file { 'geoip.conf':
    ensure  => file,
    path    => "${::apache2::mod_dir}/geoip.conf",
    mode    => $::apache2::file_mode,
    content => template('apache2/mod/geoip.conf.erb'),
    require => Exec["mkdir ${::apache2::mod_dir}"],
    before  => File[$::apache2::mod_dir],
    notify  => Class['apache2::service'],
  }

}
