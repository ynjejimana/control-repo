class apache {
  package { 'httpd': ensure => installed }
  service { 'httpd': ensure => true, enable => true, require => Package['httpd'] }
}
