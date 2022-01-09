class apache2::mod::proxy_ajp {
  Class['::apache2::mod::proxy'] -> Class['::apache2::mod::proxy_ajp']
  ::apache2::mod { 'proxy_ajp': }
}
