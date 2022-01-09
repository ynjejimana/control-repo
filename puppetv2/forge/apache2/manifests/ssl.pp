# Class: apache2::ssl
#
# This class installs Apache SSL capabilities
#
# Parameters:
# - The $ssl_package name from the apache2::params class
#
# Actions:
#   - Install Apache SSL capabilities
#
# Requires:
#
# Sample Usage:
#
class apache2::ssl {
  warning('apache2::ssl is deprecated; please use apache2::mod::ssl')
  include ::apache2::mod::ssl
}
