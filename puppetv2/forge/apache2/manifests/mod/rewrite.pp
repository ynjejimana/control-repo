class apache2::mod::rewrite {
  include ::apache2::params
  ::apache2::mod { 'rewrite': }
}
