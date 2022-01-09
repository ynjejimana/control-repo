class apache2::mod::dev {
  # Development packages are not apache modules
  warning('apache2::mod::dev is deprecated; please use apache2::dev')
  include ::apache2::dev
}
