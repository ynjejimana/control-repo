class apache2::mod::proxy_html {
  include ::apache2
  Class['::apache2::mod::proxy'] -> Class['::apache2::mod::proxy_html']
  Class['::apache2::mod::proxy_http'] -> Class['::apache2::mod::proxy_html']

  # Add libxml2
  case $::osfamily {
    /RedHat|FreeBSD|Gentoo/: {
      ::apache2::mod { 'xml2enc': }
      $loadfiles = undef
    }
    'Debian': {
      $gnu_path = $::hardwaremodel ? {
        'i686'  => 'i386',
        default => $::hardwaremodel,
      }
      $loadfiles = $::apache2::params::distrelease ? {
        '6'     => ['/usr/lib/libxml2.so.2'],
        '10'    => ['/usr/lib/libxml2.so.2'],
        default => ["/usr/lib/${gnu_path}-linux-gnu/libxml2.so.2"],
      }
      if versioncmp($::apache2::apache_version, '2.4') >= 0 {
        ::apache2::mod { 'xml2enc': }
      }
    }
  }

  ::apache2::mod { 'proxy_html':
    loadfiles => $loadfiles,
  }

  # Template uses $icons_path
  file { 'proxy_html.conf':
    ensure  => file,
    path    => "${::apache2::mod_dir}/proxy_html.conf",
    mode    => $::apache2::file_mode,
    content => template('apache2/mod/proxy_html.conf.erb'),
    require => Exec["mkdir ${::apache2::mod_dir}"],
    before  => File[$::apache2::mod_dir],
    notify  => Class['apache2::service'],
  }
}
