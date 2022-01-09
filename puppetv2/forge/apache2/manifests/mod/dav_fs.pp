class apache2::mod::dav_fs {
  $dav_lock = $::osfamily ? {
    'debian'  => "\${APACHE_LOCK_DIR}/DAVLock",
    'freebsd' => '/usr/local/var/DavLock',
    default   => '/var/lib/dav/lockdb',
  }

  Class['::apache2::mod::dav'] -> Class['::apache2::mod::dav_fs']
  ::apache2::mod { 'dav_fs': }

  # Template uses: $dav_lock
  file { 'dav_fs.conf':
    ensure  => file,
    path    => "${::apache2::mod_dir}/dav_fs.conf",
    mode    => $::apache2::file_mode,
    content => template('apache2/mod/dav_fs.conf.erb'),
    require => Exec["mkdir ${::apache2::mod_dir}"],
    before  => File[$::apache2::mod_dir],
    notify  => Class['apache2::service'],
  }
}
