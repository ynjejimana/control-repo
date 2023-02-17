class apache {
  package { 'httpd': ensure => installed }
  service { 'httpd': ensure => true, enable => true, hasstatus => false, require => Package['httpd'] }
}
