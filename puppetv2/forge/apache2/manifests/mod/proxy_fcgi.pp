class apache2::mod::proxy_fcgi {
  Class['::apache2::mod::proxy'] -> Class['::apache2::mod::proxy_fcgi']
  ::apache2::mod { 'proxy_fcgi': }
}
