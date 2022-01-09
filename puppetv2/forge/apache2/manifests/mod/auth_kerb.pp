class apache2::mod::auth_kerb {
  include ::apache2
  ::apache2::mod { 'auth_kerb': }
}


