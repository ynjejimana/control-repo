# Class common::adauth::client
#
# The parameters should be defined like this in hiera:
#
# common::adauth::client::domain: "accenture.local"
# common::adauth::client::realm: "ACCENTURE.LOCAL"
# common::adauth::client::servers:
#   aesgsilwdc01.accenture.local:
#     ip: 10.197.212.100
#     host_aliases: [ "aesgsilwdc01.esbu.lab.com.au", "aesgsilwdc01" ]
#   aesgsilwdc02.accenture.local:
#     ip: 10.197.212.200
#     host_aliases: [ "aesgsilwdc02.esbu.lab.com.au", "aesgsilwdc02" ]
#
# common::adauth::client::primary_kdc: aesgsilwdc01.accenture.local
# common::adauth::client::secondary_kdc: aesgsilwdc02.accenture.local
# common::adauth::client::ad_access_filter: "memberOf=CN=SSH Users,OU=AESG Users,DC=accenture,DC=local"
# common::adauth::client::principal: Administrator
# common::adauth::client::password: "Heidegger Heidegger was a boozy beggar"
#
# It is possible to use either "ad" as the $access_provider, or "simple". If "ad" is used, $ad_access_filter
# should be populated with the DN of the AD group whose members should be allowed SSH access; if "simple" is
# used, $simple_allow_groups should be populated with the POSIX name of the group whose members should be
# allowed access (for example, "SSH Users").
#
# The AD servers are specified both in the 'servers' hash and primary_kdc and secondary_kdc as it seems that
# hashes in puppet are not ordered, so I can't rely on the 'servers' hash being in the order that the elements
# are declared. Hence the need for explicit primary_kdc and secondary_kdc. Maybe one day someone can make
# this more elegant.
#
# For RHEL 7 we are using realmd and it requires the following packages realmd, adcli, oddjob, oddjob-mkhomedir and sssd.
# it creates /etc/realmd.conf from erb template with defaults required for join.
# it requires the following variables: domain, realm, principal and password

class common::adauth::client (
  $domain               = '',
  $realm                = '',
  $servers              = '',
  $primary_kdc          = '',
  $secondary_kdc        = '',
  $ad_access_filter     = '',
  $simple_allow_groups  = '',
  $access_provider      = 'ad',
  $principal            = '',
  $default_shell        = '/bin/bash',
  $password             = 'Welcome123',
) {
  if $domain == '' {
    fail('A $domain value is required.')
  }

  if $realm == '' {
    $realm  = upcase($domain)
  }

  if $principal == '' {
    fail('A $principal value is required.')
  }

  # Create /etc/hosts file entries for the AD servers
  create_resources(host, $servers)

  if ($::osfamily == 'RedHat') and ($::operatingsystemmajrelease >= '7') {

    # Required for sssd.conf
    $catenated_server_names = "${primary_kdc}, ${secondary_kdc}"

    # Create /etc/realmd.conf file for setting defaults
    file { '/etc/realmd.conf':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('common/adauth/realmd.conf.erb'),
    }

    # Install required packages so we can join AD domain
    $realmd_packages = ['realmd', 'adcli', 'oddjob', 'oddjob-mkhomedir', 'sssd', 'samba-common-tools']
    package { $realmd_packages :
      ensure => installed,
    }

    # configure ssh access via AD domain security groups
    if $access_provider == 'simple' {
      augeas { 'sssd.conf':
        context =>  '/files/etc/sssd/sssd.conf',
        changes =>  [
          "set target[. = 'domain/${domain}']/access_provider simple",
          "set target[. = 'domain/${domain}']/simple_allow_groups \"${simple_allow_groups}\"",
        ],
      }
    } elsif $access_provider == 'esbuad' {
      augeas { 'sssd.conf':
        context =>  '/files/etc/sssd/sssd.conf',
        changes =>  [
          "set target[. = 'domain/${domain}'] domain/${domain}",
          "set target[. = 'domain/${domain}']/access_provider simple",
          "set target[. = 'domain/${domain}']/ad_domain ${domain}",
          "set target[. = 'domain/${domain}']/ad_enable_gc False",
          "set target[. = 'domain/${domain}']/ad_server \"${catenated_server_names}\"",
          "set target[. = 'domain/${domain}']/auth_provider ad",
          "set target[. = 'domain/${domain}']/auto_private_groups true",
          "set target[. = 'domain/${domain}']/cache_credentials True",
          "set target[. = 'domain/${domain}']/default_shell ${default_shell}",
          "set target[. = 'domain/${domain}']/fallback_homedir /home/%u",
          "set target[. = 'domain/${domain}']/id_provider ad",
          "set target[. = 'domain/${domain}']/krb5_realm ${realm}",
          "set target[. = 'domain/${domain}']/krb5_store_password_if_offline True",
          "set target[. = 'domain/${domain}']/ldap_id_mapping True",
          "set target[. = 'domain/${domain}']/ldap_user_ssh_public_key sshPublicKey",
          "set target[. = 'domain/${domain}']/override_homedir /home/%u",
          "set target[. = 'domain/${domain}']/realmd_tags 'manages-system joined-with-samba'",
          "set target[. = 'domain/${domain}']/simple_allow_groups \"${simple_allow_groups}\"",
          "set target[. = 'sssd']/domains '${domain}'",
          "set target[. = 'sssd']/services 'nss, pam, sudo, ssh'",
          "set target[. = 'ssh'] ssh",
          "set target[. = 'sudo'] sudo",
        ],
        notify => Service['sssd']
      }
      augeas { 'nsswitch.conf':
        context =>  '/files/etc/nsswitch.conf',
        changes =>  [
          "set database[. = 'sudoers'] sudoers",
          "set database[. = 'sudoers']/service[1] 'files'",
          "set database[. = 'sudoers']/service[2] 'sss'",
        ],
      }
    }

    # Join the AD domain
    exec { 'realmd_join_domain':
      command =>  "/bin/bash -c '/bin/echo -n ${password} | /usr/sbin/realm join --user=${principal}@${domain} ${realm}'",
      unless  =>  "/usr/sbin/realm list | grep -qi ${domain}$",
      require =>  [ Package[$realmd_packages], File['/etc/realmd.conf'] ],
    }

    # Restart sssd if domain join has occurred
    service { 'sssd':
      enable     => 'true',
      ensure     => 'running',
      hasrestart => 'true',
      subscribe  =>  Exec['realmd_join_domain'],
    }

  } else {

    if defined(Class['common::ipa::client']) {
    require common::ipa::client
    }

    if !is_hash($servers) {
      fail('A $servers value is required, and it must be a hash, even if there is only one server.')
    }

    if $primary_kdc == '' {
      fail('A $primary_kdc value is required.')
    }

    if $ad_access_filter == '' and $simple_allow_groups == '' {
      fail('Either an $ad_access_filter value or a $simple_allow_groups value is required.')
    }

    # Define some variables from the $servers variable
    $server_names = keys($servers)
    $catenated_server_names = "${primary_kdc}, ${secondary_kdc}"


    # Install 'adcli' so we can join the AD domain
    package { 'adcli':
      ensure   =>  installed,
    }


    # Join the AD domain
    exec { 'adcli_join_domain':
      command =>  "/bin/bash -c '/bin/echo -n ${password} | /usr/sbin/adcli join -S ${primary_kdc} -D ${domain} -H ${::fqdn} -U ${principal}'",
      unless  =>  "/usr/bin/klist -k | grep -qi ${domain}$",
      require =>  [ Package['adcli'], Host[keys($servers)] ],
    }


    # Restart sssd if domain join has occurred
    exec { 'restart_sssd':
      command     =>  '/sbin/service sssd restart',
      refreshonly =>  true,
      subscribe   =>  Exec['adcli_join_domain'],
    }

    # Configure sssd.conf with the new AD domain
    if $access_provider == 'ad' {
      augeas { 'sssd.conf':
        context =>  '/files/etc/sssd/sssd.conf',
        changes =>  [
          "set target[. = 'domain/${domain}'] domain/${domain}",
          "set target[. = 'domain/${domain}']/ad_server \"${catenated_server_names}\"",
          "set target[. = 'domain/${domain}']/ad_domain ${domain}",
          "set target[. = 'domain/${domain}']/id_provider ad",
          "set target[. = 'domain/${domain}']/auth_provider ad",
          "set target[. = 'domain/${domain}']/access_provider ${access_provider}",
          "set target[. = 'domain/${domain}']/ad_hostname ${::hostname}.${domain}",
          "set target[. = 'domain/${domain}']/fallback_homedir /home/%u",
          "set target[. = 'domain/${domain}']/ldap_schema ad",
          "set target[. = 'domain/${domain}']/ad_enable_gc False",
          "set target[. = 'domain/${domain}']/dyndns_update False",
          "set target[. = 'domain/${domain}']/ad_access_filter \"${domain}:(${ad_access_filter})\"",
          "set target[. = 'domain/${domain}']/override_homedir /home/%u",
          "set target[. = 'domain/${domain}']/default_shell ${default_shell}",
          "set target[. = 'sssd']/domains 'esbu.lab.com.au, ${domain}'",
        ],
      }
    } elsif $access_provider == 'simple' {
      augeas { 'sssd.conf':
        context =>  '/files/etc/sssd/sssd.conf',
        changes =>  [
          "set target[. = 'domain/${domain}'] domain/${domain}",
          "set target[. = 'domain/${domain}']/ad_server \"${catenated_server_names}\"",
          "set target[. = 'domain/${domain}']/ad_domain ${domain}",
          "set target[. = 'domain/${domain}']/id_provider ad",
          "set target[. = 'domain/${domain}']/auth_provider ad",
          "set target[. = 'domain/${domain}']/access_provider ${access_provider}",
          "set target[. = 'domain/${domain}']/ad_hostname ${::hostname}.${domain}",
          "set target[. = 'domain/${domain}']/fallback_homedir /home/%u",
          "set target[. = 'domain/${domain}']/ldap_schema ad",
          "set target[. = 'domain/${domain}']/ad_enable_gc False",
          "set target[. = 'domain/${domain}']/dyndns_update False",
          "set target[. = 'domain/${domain}']/simple_allow_groups \"${simple_allow_groups}\"",
          "set target[. = 'domain/${domain}']/override_homedir /home/%u",
          "set target[. = 'domain/${domain}']/default_shell ${default_shell}",
          "set target[. = 'sssd']/domains 'esbu.lab.com.au, ${domain}'",
        ],
      }
    } else {
      fail('$access_provider should be either "ad" or "simple".')
    }


    # Configure the Kerberos client with the AD domain
    if $secondary_kdc == '' {
      augeas { 'krb5.conf':
        context =>  '/files/etc/krb5.conf',
        lens    =>  'Krb5.lns',
        incl    =>  '/etc/krb5.conf',
        changes =>  [
          "set realms/realm[. = '${realm}'] ${realm}",
          "set realms/realm[. = '${realm}']/kdc[1] ${primary_kdc}",
          "set realms/realm[. = '${realm}']/master_kdc ${primary_kdc}",
          "set realms/realm[. = '${realm}']/admin_server ${primary_kdc}",
          "set realms/realm[. = '${realm}']/default_domain ${domain}",
          "set domain_realm/.${domain} ${realm}",
          "set domain_realm/${domain} ${realm}",
        ]
      }
    } else {
      augeas { 'krb5.conf':
        context =>  '/files/etc/krb5.conf',
        lens    =>  'Krb5.lns',
        incl    =>  '/etc/krb5.conf',
        changes =>  [
          "set realms/realm[. = '${realm}'] ${realm}",
          "set realms/realm[. = '${realm}']/kdc[1] ${primary_kdc}",
          "set realms/realm[. = '${realm}']/kdc[2] ${secondary_kdc}",
          "set realms/realm[. = '${realm}']/master_kdc ${primary_kdc}",
          "set realms/realm[. = '${realm}']/admin_server ${primary_kdc}",
          "set realms/realm[. = '${realm}']/default_domain ${domain}",
          "set domain_realm/.${domain} ${realm}",
          "set domain_realm/${domain} ${realm}",
        ]
      }
    }
  }

}
