# Class: apache2::proxy
#
# This class enabled the proxy module for Apache
#
# Actions:
#   - Enables Apache Proxy module
#
# Requires:
#
# Sample Usage:
#
class apache2::proxy {
  warning('apache2::proxy is deprecated; please use apache2::mod::proxy')
  include ::apache2::mod::proxy
}
