class { 'apache':
  mpm_module => 'prefork',
}
include apache2::mod::php
