class apache2::mod::userdir (
  $home = '/home',
  $dir = 'public_html',
  $disable_root = true,
  $apache_version = $::apache2::apache_version,
  $options = [ 'MultiViews', 'Indexes', 'SymLinksIfOwnerMatch', 'IncludesNoExec' ],
) {
  ::apache2::mod { 'userdir': }

  # Template uses $home, $dir, $disable_root, $apache_version
  file { 'userdir.conf':
    ensure  => file,
    path    => "${::apache2::mod_dir}/userdir.conf",
    mode    => $::apache2::file_mode,
    content => template('apache2/mod/userdir.conf.erb'),
    require => Exec["mkdir ${::apache2::mod_dir}"],
    before  => File[$::apache2::mod_dir],
    notify  => Class['apache2::service'],
  }
}
