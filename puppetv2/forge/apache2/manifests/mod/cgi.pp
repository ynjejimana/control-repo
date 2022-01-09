class apache2::mod::cgi {
  case $::osfamily {
    'FreeBSD': {}
    default: {
      Class['::apache2::mod::prefork'] -> Class['::apache2::mod::cgi']
    }
  }

  ::apache2::mod { 'cgi': }
}
