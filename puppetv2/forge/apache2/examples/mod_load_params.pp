# Tests the path and identifier parameters for the apache2::mod class

# Base class for clarity:
class { 'apache': }


# Exaple parameter usage:
apache2::mod { 'testmod':
  path => '/usr/some/path/mod_testmod.so',
  id   => 'testmod_custom_name',
}
