class puppet::server (
  $version = installed,
  $dns_alt_names = [],
  $foreman_server_url = 'foreman.esbu.lab.com.au',
  $servername = 'puppet.esbu.lab.com.au',
  $ca = false,
  $ca_server,
  $noclient = true,
  $puppet_provider = 'puppetssh',
  $puppet_environments,
) {

  $install_version = $::osfamily ? {
    'RedHat' => "${version}-1.el${::operatingsystemmajrelease}",
    default  => $version,
  }

  package { 'puppet':
    ensure => $install_version,
    notify => Service['httpd'],
  }

  if $::osfamily == 'RedHat' {
    package { ['yum-plugin-versionlock']:
      ensure => installed,
    }

    exec { 'remove-puppet-versionlock':
      command => 'yum versionlock delete puppet; yum versionlock delete puppet-server',
      path    => '/usr/bin:/usr/sbin:/bin:/usr/local/bin:/sbin',
      onlyif  => "yum versionlock list | grep puppet && ! rpm -qa | grep puppet-${install_version}",
      before  => Package['puppet'],
      require => Package['yum-plugin-versionlock'],
    }

    exec { 'add-puppet-versionlock':
      command => 'yum versionlock add puppet; yum versionlock add puppet-server',
      path    => '/usr/bin:/usr/sbin:/bin:/usr/local/bin:/sbin',
      onlyif  => "rpm -qa | grep puppet-${install_version} && ! yum versionlock list | grep puppet",
      require => [ Package['puppet'], Package['yum-plugin-versionlock'] ],
    }
  }

  File {
    owner => puppet,
    group => puppet,
    mode  => '0644',
  }

  file { '/etc/puppet/node.rb':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0755',
    content => template('puppet/node.rb.erb'),
    notify  => Service['httpd'],
  }

  file { '/var/lib/puppet/reports':
    ensure  => directory,
    owner   => 'puppet',
    group   => 'puppet',
    recurse => true,
    require => Package['puppet'],
  }

  file { '/etc/puppet':
    ensure  => directory,
    owner   => 'puppet',
    group   => 'puppet',
    require => Package['puppet'],
  }

  $siterubypath = $::operatingsystemmajrelease ? {
    '7'     => '/usr/share/ruby/vendor_ruby/puppet/reports',
    default => '/usr/lib/ruby/site_ruby/1.8/puppet/reports',
  }

  file { "${siterubypath}/foreman.rb":
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('puppet/foreman-reports.rb.erb'),
    notify  => Service['httpd'],
  }

  file { '/etc/puppet/modules/common':
    ensure => absent,
  }

  file { '/etc/puppet/puppet.conf':
    ensure  => file,
    content => template('puppet/puppetmaster_puppet.conf.erb'),
    require => Package['puppet'],
    notify  => Service['httpd'],
  }

  file { '/etc/puppet/auth.conf':
    ensure  => file,
    content => template('puppet/puppetmaster_auth.conf.erb'),
    require => Package['puppet'],
    notify  => Service['httpd'],
  }

  file { '/etc/sysconfig/puppet':
    content => template('puppet/sysconfig.erb'),
    owner   => root,
    group   => root,
  }

  file { '/etc/puppet/hiera.yaml':
    ensure  => file,
    content => template('puppet/hiera.yaml.erb'),
    notify  => Service['httpd'],
  }

  file { '/etc/puppet/pull.sh':
    ensure => file,
    source => 'puppet:///modules/puppet/pull.sh',
    mode   => '0755',
  }

  file { '/etc/puppet/rack/':
    ensure  => directory,
    owner   => 'puppet',
    group   => 'puppet',
    mode    => '0755',
    require => Package['puppet'],
  }

  file { '/etc/puppet/rack/config.ru':
    ensure  => file,
    owner   => 'puppet',
    group   => 'puppet',
    mode    => '0755',
    source  => 'puppet:///modules/puppet/config.ru',
    require => File['/etc/puppet/rack/'],
    notify  => Service['httpd'],
  }

  file { '/etc/puppet/autosign.conf':
    ensure  => file,
    owner   => 'foreman-proxy',
    group   => 'puppet',
    mode    => '0664',
    replace => false,
  }

  $git_server = hiera('git_server')

  cron { 'update-puppet-code':
    command  => '/etc/puppet/pull.sh > /etc/puppet/pull.sh.log 2>&1',
    user     => 'root',
    month    => '*',
    monthday => '*',
    hour     => '*',
    minute   => '*/5',
    require  => File['/etc/puppet/pull.sh'],
  }

  class { '::foreman_proxy':
    puppet          => true,
    puppetca        => $ca,
    puppet_version  => hiera('common::foreman_proxy::install::puppet_version'),
    puppet_provider => $puppet_provider,
  }

  class { '::apache2':
    default_vhost     => false,
    default_ssl_vhost => false,
  }
  class { '::apache2::mod::ssl': }
  class { '::apache2::mod::proxy': }
  class { '::apache2::mod::proxy_http': }
  class { '::apache2::mod::headers': }

  $passenger_root = $::operatingsystemmajrelease ? {
    '7'     => '/usr/share/passenger/phusion_passenger/locations.ini',
    default => '/usr/lib/ruby/gems/1.8/gems/passenger-4.0.18/lib/phusion_passenger/locations.ini',
  }
  
  $passenger_packages = [ 'mod_passenger', 'rubygem-passenger', 'rubygem-passenger-native', 'rubygem-passenger-native-libs' ]
  package { $passenger_packages:
    ensure => installed,
  }

  class { 'apache2::mod::passenger':
    passenger_root => $passenger_root,
    passenger_ruby => '/usr/bin/ruby',
    manage_repo    => false,
  }

  # Configure our own httpd.service file so we can make PrivateTmp=false, so that 'passenger-status' will work
  file { '/etc/systemd/system/httpd.service':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/puppet/httpd.service',
    require => Class['::apache2'],
    notify  => [ Exec['systemctl-daemon-reload'], Service['httpd'] ],
  }

  exec { 'systemctl-daemon-reload':
    command     => 'systemctl daemon-reload',
    refreshonly => true,
    path        => '/bin:/usr/bin:/sbin:/usr/sbin',
  }

  if $ca == true {
    $ssl_chain = '/var/lib/puppet/ssl/ca/ca_crt.pem'
    $ssl_crl = '/var/lib/puppet/ssl/ca/ca_crl.pem'
    $ssl_crl_check = 'chain'
    $ssl_ca = '/var/lib/puppet/ssl/ca/ca_crt.pem'
    $ssl_proxyengine = false
    $proxy_pass_match = undef
  } else {
    $ssl_chain = undef
    $ssl_crl = undef
    $ssl_crl_check = undef
    $ssl_ca = '/var/lib/puppet/ssl/certs/ca.pem'
    $ssl_proxyengine = true
    $proxy_pass_match = {
      path => '^(/.*?)/(certificate.*?)/(.*)$',
      url  => 'https://puppetca.esbu.lab.com.au:8140/',
    }
  }

  apache2::vhost { 'puppet':
    servername           => $servername,
    port                 => '8140',
    docroot              => '/etc/puppet/rack/public',
    docroot_owner        => 'puppet',
    directories          => [ {
      path                 => '/etc/puppet/rack/public',
      allow_override       => 'None',
      passenger_enabled    => 'On', } ],
    access_log_file      => '/var/log/httpd/puppet_access_ssl.log',
    error_log_file       => 'puppet_error_ssl.log',
    ssl                  => true,
    ssl_ca               => $ssl_ca,
    ssl_cert             => "/var/lib/puppet/ssl/certs/${::fqdn}.pem",
    ssl_certs_dir        => '/etc/pki/tls/certs',
    ssl_key              => "/var/lib/puppet/ssl/private_keys/${::fqdn}.pem",
    ssl_chain            => $ssl_chain,
    ssl_crl              => $ssl_crl,
    ssl_crl_check        => $ssl_crl_check,
    ssl_cipher           => 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH',
    ssl_honorcipherorder => 'on',
    ssl_protocol         => 'ALL -SSLv2 -SSLv3',
    ssl_verify_client    => 'optional',
    ssl_verify_depth     => '1',
    ssl_options          => '+StdEnvVars +ExportCertData',
    ssl_proxyengine      => $ssl_proxyengine,
    priority             => '25',
    request_headers      => [ 'set X-SSL-Subject %{SSL_CLIENT_S_DN}e',
                              'set X-Client-DN %{SSL_CLIENT_S_DN}e',
                              'set X-Client-Verify %{SSL_CLIENT_VERIFY}e',
                              'unset X-Forwarded-For' ],
    proxy_pass_match     => $proxy_pass_match,
  }

  Augeas {
    notify => Service['httpd'],
  }

  if $ca == true {
    augeas { 'Allow Non-CA Puppetmasters to proxy CA requests to Puppet CA':
      context => '/etc/puppet/auth.conf',
      changes => ["set path[last()+1] '/certificate_revocation_list'",
                  "set path[. = '/certificate_revocation_list']/auth any",
                  "set path[. = '/certificate_revocation_list']/method find",
                  "set path[. = '/certificate_revocation_list']/allow '*'",
                 ],
      onlyif  => "match path[. = '/certificate_revocation_list'] size == 0",
    }
  }
}
