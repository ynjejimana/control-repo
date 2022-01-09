# Class: apache2::php
#
# This class installs PHP for Apache
#
# Parameters:
# - $php_package
#
# Actions:
#   - Install Apache PHP package
#
# Requires:
#
# Sample Usage:
#
class apache2::php {
  warning('apache2::php is deprecated; please use apache2::mod::php')
  include ::apache2::mod::php
}
