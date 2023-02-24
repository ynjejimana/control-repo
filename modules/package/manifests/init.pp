class package {
  package { 'httpd': ensure => installed }
  service { 'httpd': ensure => true, enable => true, require => Package['httpd']}

  package { 'vim': ensure => installed }
  package { 'wget': ensure => installed }
  package { 'curl': ensure => installed }
  package { 'git': ensure => installed }

}
