class ntta::postfix::install ($relayhost = undef, $smtp_listen = $::ipaddress, $fallback_relay = undef ) {

  class { 'postfix':
    smtp_listen => $smtp_listen,
  }

  if $fallback_relay != undef {
    postfix::config { "fallback_relay":
      value => $fallback_relay
    }
  }

  postfix::config { "mynetworks":
    value   => "/etc/postfix/mynetworks",
    require => File["/etc/postfix/mynetworks"],
  }

  postfix::config { "transport_maps":
    value => "hash:/etc/postfix/transport",
  }

  postfix::hash { "/etc/postfix/transport":
    ensure => present,
    source => "puppet:///modules/ntta/postfix/transport",
  }

  # Needed to stop postfix looking up ipv6 DNS records
  postfix::config { "inet_protocols":
    value => "ipv4",
  }

  if $relayhost == undef {
    $relayhost_ensure = "blank"
  }
  else {
    $relayhost_ensure = "present"
  }

  postfix::config { "relayhost":
    value  => $relayhost,
    ensure => $relayhost_ensure,
  }

  File {
    owner => "root",
    group => "root",
    mode => "0644",
  }

  file {
    '/etc/postfix/access_client':
      source => "puppet:///modules/ntta/postfix/access_client";
    '/etc/postfix/access_recipient':
      source => "puppet:///modules/ntta/postfix/access_recipient";
    '/etc/postfix/body_checks':
      source => "puppet:///modules/ntta/postfix/body_checks";
    '/etc/postfix/mynetworks':
      source =>
        ["puppet:///modules/ntta/postfix/mynetworks.${::hostname}",
        "puppet:///modules/ntta/postfix/mynetworks"];
    '/etc/postfix/relay':
      source =>
        ["puppet:///modules/ntta/postfix/relay.${::hostname}",
        "puppet:///modules/ntta/postfix/relay"];
   }

   cron { "flush-postqueue":
     command  => "/usr/sbin/postqueue -f",
     user     => "root",
     month    => "*",
     monthday => "*",
     hour     => "*",
     minute   => "*/5",
   }

}