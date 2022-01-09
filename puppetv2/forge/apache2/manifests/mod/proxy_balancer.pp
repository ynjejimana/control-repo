class apache2::mod::proxy_balancer {

  include ::apache2::mod::proxy
  include ::apache2::mod::proxy_http

  Class['::apache2::mod::proxy'] -> Class['::apache2::mod::proxy_balancer']
  Class['::apache2::mod::proxy_http'] -> Class['::apache2::mod::proxy_balancer']
  ::apache2::mod { 'proxy_balancer': }

}
