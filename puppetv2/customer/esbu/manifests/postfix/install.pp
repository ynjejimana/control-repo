class esbu::postfix::install (
  $relayhost = undef,
  $smtp_listen = $::ipaddress,
  $fallback_relay = undef,
  $no_transport = false,
  $inet_protocols = 'ipv4',
  $inet_interfaces = 'all',
  $master_smtp = undef,
  $master_smtps = undef,
  $smtp_tls_security_level = undef,
  $smtp_tls_loglevel = undef,
  $myorigin = undef,
  $mydomain = undef,
  $mydestination = undef,
  $relay_domains = undef,
  $mynetworks = undef,
  $header_checks = undef,
  $smtp_generic_maps = undef,
  $sender_canonical_maps = undef,
  $transport_maps = [],
) {

  class { 'postfix':
    smtp_listen     => $smtp_listen,
    inet_interfaces => $inet_interfaces,
    master_smtp     => $master_smtp,
    master_smtps    => $master_smtps,
    myorigin        => $myorigin,
  }

  if $smtp_tls_security_level != undef {
    postfix::config { 'smtp_tls_security_level':
    value => $smtp_tls_security_level
    }
  }

  if $smtp_tls_loglevel != undef {
    postfix::config { 'smtp_tls_loglevel':
    value => $smtp_tls_loglevel
    }
  }

  if $mydestination != undef {
    postfix::config { 'mydestination':
    value => $mydestination
    }
  }

  if $relay_domains != undef {
    postfix::config { 'relay_domains':
    value => $relay_domains
    }
  }

  if $fallback_relay != undef {
    if $::osfamily == 'RedHat' {
      if $::operatingsystemmajrelease >= '7' {
        postfix::config { 'smtp_fallback_relay':
        value => $fallback_relay
        }
      } else {
        postfix::config { 'fallback_relay':
        value => $fallback_relay
        }
      }
    } else {
      postfix::config { 'fallback_relay':
      value => $fallback_relay
      }
    }
  }

  if $mydomain != undef {
    postfix::config { 'mydomain':
    value => $mydomain
    }
  }

  postfix::config { 'mynetworks':
    value   => '/etc/postfix/mynetworks',
    require => File['/etc/postfix/mynetworks'],
  }

  if $header_checks != undef {
    esbu::postfix::configparams{
      'header_checks': configname => 'header_checks', configfilename => 'header_checks', valuetype => 'regexp';
    }
  }


  if $smtp_generic_maps != undef {
    esbu::postfix::configparams{
      'smtp_generic_maps': configname => 'smtp_generic_maps', configfilename => 'generic', valuetype => 'hash';
    }
  }

  if $sender_canonical_maps != undef {
    esbu::postfix::configparams{
      'sender_canonical': configname => 'sender_canonical_maps', configfilename => 'sender_canonical', valuetype => 'regexp';
    }
  }

  if ! $no_transport {
    postfix::config { 'transport_maps':
          value => 'hash:/etc/postfix/transport',
    }

    postfix::hash { '/etc/postfix/transport':
      ensure  => present,
      content => template('esbu/postfix/transport.erb');
    }
  }

  # Needed to stop postfix looking up ipv6 DNS records
  postfix::config { 'inet_protocols':
    value => $inet_protocols,
  }

  if $relayhost == undef {
    $relayhost_ensure = 'absent'
  }
  else {
    $relayhost_ensure = 'present'
  }

  postfix::config { 'relayhost':
    ensure => $relayhost_ensure,
    value  => $relayhost,
  }

  File {
    owner => 'root',
    group => 'root',
    mode => '0644',
  }

  if $mynetworks != undef {
    file { '/etc/postfix/mynetworks':
      content => template('esbu/postfix/mynetworks.erb');
    }
  }
  else {
    file { '/etc/postfix/mynetworks':
      source => ["puppet:///modules/esbu/postfix/mynetworks.${::hostname}",
        'puppet:///modules/esbu/postfix/mynetworks'];
    }
  }

  file {
    '/etc/postfix/access_client':
      source => 'puppet:///modules/esbu/postfix/access_client';
    '/etc/postfix/access_recipient':
      source => 'puppet:///modules/esbu/postfix/access_recipient';
    '/etc/postfix/body_checks':
      source => 'puppet:///modules/esbu/postfix/body_checks';
    '/etc/postfix/relay':
      source =>
      ["puppet:///modules/esbu/postfix/relay.${::hostname}",
      'puppet:///modules/esbu/postfix/relay'];
  }

  cron { 'flush-postqueue':
    command  => '/usr/sbin/postqueue -f',
    user     => 'root',
    month    => '*',
    monthday => '*',
    hour     => '*',
    minute   => '*/5',
  }

}

