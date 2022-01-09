class apache2::mod::xsendfile {
  include ::apache2::params
  ::apache2::mod { 'xsendfile': }
}
