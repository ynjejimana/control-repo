class apache2::mod::nss (
  $transfer_log = "${::apache2::params::logroot}/access.log",
  $error_log    = "${::apache2::params::logroot}/error.log",
  $passwd_file  = undef,
  $port     = 8443,
) {
  include ::apache2::mod::mime

  apache2::mod { 'nss': }

  $httpd_dir = $::apache2::httpd_dir

  # Template uses:
  # $transfer_log
  # $error_log
  # $http_dir
  # passwd_file
  file { 'nss.conf':
    ensure  => file,
    path    => "${::apache2::mod_dir}/nss.conf",
    mode    => $::apache2::file_mode,
    content => template('apache2/mod/nss.conf.erb'),
    require => Exec["mkdir ${::apache2::mod_dir}"],
    before  => File[$::apache2::mod_dir],
    notify  => Class['apache2::service'],
  }
}
