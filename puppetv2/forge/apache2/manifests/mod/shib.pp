class apache2::mod::shib (
  $suppress_warning = false,
) {
  include ::apache2
  if $::osfamily == 'RedHat' and ! $suppress_warning {
    warning('RedHat distributions do not have Apache mod_shib in their default package repositories.')
  }

  $mod_shib = 'shib2'

  apache2::mod {$mod_shib:
    id => 'mod_shib',
  }

}
