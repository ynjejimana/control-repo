class apache2::mod::deflate (
  $types = [
    'text/html text/plain text/xml',
    'text/css',
    'application/x-javascript application/javascript application/ecmascript',
    'application/rss+xml',
    'application/json'
  ],
  $notes = {
    'Input'  => 'instream',
    'Output' => 'outstream',
    'Ratio'  => 'ratio'
  }
) {
  include ::apache2
  ::apache2::mod { 'deflate': }

  file { 'deflate.conf':
    ensure  => file,
    path    => "${::apache2::mod_dir}/deflate.conf",
    mode    => $::apache2::file_mode,
    content => template('apache2/mod/deflate.conf.erb'),
    require => Exec["mkdir ${::apache2::mod_dir}"],
    before  => File[$::apache2::mod_dir],
    notify  => Class['apache2::service'],
  }
}
