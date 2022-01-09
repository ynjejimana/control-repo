define apache2::fastcgi::server (
  $host          = '127.0.0.1:9000',
  $timeout       = 15,
  $flush         = false,
  $faux_path     = "/var/www/${name}.fcgi",
  $fcgi_alias    = "/${name}.fcgi",
  $file_type     = 'application/x-httpd-php',
  $pass_header   = undef,
) {
  include apache2::mod::fastcgi

  Apache2::Mod['fastcgi'] -> Apache2::Fastcgi::Server[$title]

  if is_absolute_path($host) {
    $socket = $host
  }

  file { "fastcgi-pool-${name}.conf":
    ensure  => present,
    path    => "${::apache2::confd_dir}/fastcgi-pool-${name}.conf",
    owner   => 'root',
    group   => $::apache2::params::root_group,
    mode    => $::apache2::file_mode,
    content => template('apache2/fastcgi/server.erb'),
    require => Exec["mkdir ${::apache2::confd_dir}"],
    before  => File[$::apache2::confd_dir],
    notify  => Class['apache2::service'],
  }
}
