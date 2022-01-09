class apache2::mod::proxy_http {
  Class['::apache2::mod::proxy'] -> Class['::apache2::mod::proxy_http']
  ::apache2::mod { 'proxy_http': }
}
