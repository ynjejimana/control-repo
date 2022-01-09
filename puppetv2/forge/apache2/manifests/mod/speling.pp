class apache2::mod::speling {
  include ::apache2
  ::apache2::mod { 'speling': }
}
