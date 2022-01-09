class apache2::mod::python {
  include ::apache2
  ::apache22::mod { 'python': }
}


