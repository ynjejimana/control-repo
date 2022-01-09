# Class: apache2::python
#
# This class installs Python for Apache
#
# Parameters:
# - $php_package
#
# Actions:
#   - Install Apache Python package
#
# Requires:
#
# Sample Usage:
#
class apache2::python {
  warning('apache2::python is deprecated; please use apache2::mod::python')
  include ::apache2::mod::python
}
