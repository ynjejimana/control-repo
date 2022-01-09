# vi:syntax=puppet:filetype=puppet:ts=4:et:
#
# Base SOE linux class that includes the bare minimum required classes
# to meet ISO27001 certification. Do not modify this class without extensively
# testing the additions as it is deployed enterprise wide.
class soe::linux (
  # Array of accounts to remove from the host. Useful for removing inbuilt non used accounts
  $remove_accounts = undef,
  $group_packages = undef, # Not implemented yet
  $lvms = undef,
  # Apply the standard OS Hardening to the linux host. Includes sysctl, disabled services etc.
  $os_hardening = false,
  # Use the new Zabbix v3.0 agent code, or stick with the old Zabbix 2.2 agent code...
  $zabbix30 = false,
  # Enable SNMP agent
  $snmpd_enabled = false,
  # Enable AD auth, can be used in conjunction with IPA to enable two different authentication sources
  $adauth = false,
  # Enable postfix installation and configuration
  $postfix = false,
  # Installs X11 libs etc and SSH X11 forwarding to allow remote graphical installs
  $x11_enabled = false,
  # Limits the number of Package resources applied per hour to once rather than every run.
  $scheduled_package_installs = false,
  # emagent
  $emagent = false,
  # logrotate
  $logrotate = false,
  # Splunk Universal Forwarder
  $splunk_universal_forwarder = false,
  # Filename of the customer specific iptables ruleset to be installed on the host.
  # The name of the file is relative to the customer/common/files/iptables/ directory.
  $iptables_rules = undef,
  # odbc
  $odbc_enabled = false,
  # nscd?
  $nscd = false,
  # symantec default
  $include_symantec = false,
  # ISO-related classes
  $include_iso_classes = true,
  # Zabbix agent
  $include_zabbix_agent = true,
  # Yum repos
  $include_yum_repos = false,
  #hiera defined class includes enable
  $hiera_class_includes = false,
  $useelasticbeatsforlogging = false,
  $enableipaclient = true,
  # facls
  $set_facl = false,
  # tuned
  $tuned_enabled = false,
  # Qualys Cloud Agent
  $include_qualys_agent = false,
  # Crowdstrike Falcon Sensor
  $include_crowdstrike_falcon = false,
  # New puppet client class
  $use_new_puppet_client_class = false,
  # DNS resolv.conf handling
  $resolvconf_enabled = true,
  # Feature flag basic SOE classes
  $puppetcron_enabled = true,
  $curl_enabled = true,
  $motd_enabled = true,
  $etcissue_enabled = true,
  $unzip_enabled = true,
  $rootaccount_enabled = true,
  $vim_enabled = true,
  $wget_enabled = true,
  $hosts_enabled = true,
  $iptablesstatus_enabled = true,
  $networkconf_enabled = true,
  $ntp_enabled = true,
  $cron_enabled = true,
  $timezone_enabled = true,
  $goss_enabled = true,
  $clamav_agent_enabled = false,
  $clamav_enabled = true,
  $sudo_enabled = true,
  $ulimit_enabled = true,
)
{
  require soe::repos
  # For some reason these weren't being automatically parsed as hashes
  # Explicitly fetching them as a hash works though...
  $mountpoints = hiera_hash('soe::linux::mountpoints', {})
  $packages = hiera_array('soe::linux::packages', [])
  $files = hiera_hash('soe::linux::files', {})
  $accounts = hiera_hash('soe::linux::accounts', {})
  $groups = hiera_hash('soe::linux::groups', {})
  $sysctl_params = hiera_hash('soe::linux::sysctl_params', {})

  if $puppetcron_enabled == true {
    include common::puppet::cron
  }
  if $curl_enabled == true {
    include common::curl::install
  }
  if $motd_enabled == true {
    include common::motd::default
  }
  if $etcissue_enabled == true {
    include common::etcissue::default
  }
  if $unzip_enabled == true {
    include common::unzip::install
  }
  if $rootaccount_enabled == true {
    include common::users::root_account
  }
  if $vim_enabled == true {
    include common::vim::install
  }
  if $wget_enabled == true {
    include common::wget::install
  }
  if $hosts_enabled == true {
    include common::hosts::default
  }
  if $iptablesstatus_enabled == true {
    include common::iptables::status
  }
  if $networkconf_enabled == true {
    include common::network::service
  }
  if $ntp_enabled == true {
    include common::ntp::client
  }
  if $cron_enabled == true {
    include common::cron::config
  }
  if $timezone_enabled == true {
    include common::timezone::config
  }
  if $goss_enabled == true {
    include common::goss::install
  }
## ClamAV uses common::clamav::agent class - instead of common::clamav::client (old one, which is incompatible with RH/Centos7). the old class is left by now - as it's used in some installs.
  if $clamav_agent_enabled == true {
    include common::clamav::agent
  }
  if $clamav_enabled == true {
    include common::clamav::client
  }
  if $sudo_enabled == true {
    include common::sudo::config
  }
  if $ulimit_enabled == true {
    include common::ulimit::config
  }

  if $use_new_puppet_client_class == true {
    include common::puppet::client_new
  } else {
    include common::puppet::client
  }

  # New ISO services
  if $include_iso_classes == true {

    if $enableipaclient == true {
      include common::ipa::client
    }

    if $useelasticbeatsforlogging == true {
      class {'common::rsyslog::client':
        remote_servers => false,
        log_remote     => false,
      } ->
      class {'common::audit::audit':}
      include common::filebeat::client
    }
    else {
      include common::audit::audit
      include common::rsyslog::client
    }
  }

  # Zabbix agent -- version 3 or the old version 2.2
  if $include_zabbix_agent == true {
    if $zabbix30 == true {
      include common::zabbix30::agent
    } else {
      include common::zabbix::agent
    }
  }

  if $snmpd_enabled == true {
    include common::snmp::agent
  } 

  if $x11_enabled == true {
    include common::x11::config
    class { 'common::ssh::server':
        x11_forwarding  => 'yes',
    }
  } else {
    include common::ssh::server
  }

  # AD auth class
  if $adauth == true {
    include common::adauth::client
  }

  # Symantec Agent class
  if $include_symantec == true {
    include common::symantec::agent
  }

  # Postfix class
  if $postfix == true {
    include esbu::postfix::install
  }

  # OS Hardening
  if $os_hardening == true {
    if soe::linux::packages != nil {
      class { 'common::os_hardening::install':
        protected_packages => $soe::linux::packages,
        require            => Class['soe::repos'],
      }
    } else {
      include common::os_hardening::install
    }
  } else {
    # these services define sysctl resources that conflict with hardening
    include common::ipv6::status
    include common::selinux::disable
  }

  #include common::users::admin_group
  #include common::users::recovery_account
  #include common::users::unix_accounts

  if $include_yum_repos == true {
    include repos::centos::centos
    include repos::centos::centos_misc
    include repos::centos::epel
    include repos::centos::foreman
    include repos::centos::foreman_plugins
    include repos::centos::scl
  }

  if $::virtual  == 'vmware' {
    include common::vmwaretools::install
  }

  if $emagent == true {
    include common::emagent::agent
  }

  if $logrotate == true {
    include common::logrotate::config
  }

  if $splunk_universal_forwarder == true {
    include common::splunk::client
  }

  # Must be soe::linux::packages as it conflicts with the in-built type
  if $soe::linux::packages != undef {
    if $scheduled_package_installs {
      schedule { 'limit_package_install_once_per_hour':
        period => hourly,
        repeat => 1,
      }
      package { $soe::linux::packages :
              ensure   => installed,
              schedule => 'limit_package_install_once_per_hour',
      }
    } else {
      # No schedule, default behaviour
      package { $soe::linux::packages :
              ensure => installed,
      }
    }
  }
  # Must be soe::linux::files as it conflicts with the in-built type
    if $soe::linux::files != {} {
        create_resources(file, $soe::linux::files)
    }
  if $groups != undef {
    create_resources(group, $soe::linux::groups)
  }
  if $soe::linux::sysctl_params != undef {
    $sysctl_defaults = {
      ensure => present,
    }
    create_resources(sysctl, $soe::linux::sysctl_params, $sysctl_defaults)
  }
  if $accounts != undef {
    create_resources(soe::account, $soe::linux::accounts)
  }
  if $remove_accounts != undef {
    create_resources(soe::account, $soe::linux::remove_accounts)
  }

  if $soe::linux::mountpoints != {} {
    create_resources(mount, $soe::linux::mountpoints)
  }
  if $soe::linux::group_packages != undef {
    yum_install_group { $soe::linux::group_packages: }
  }

  if $soe::linux::odbc_enabled == true {
    include common::odbc::client
  }

  if $soe::linux::nscd == true {
    include common::nscd::install
  }

  if $soe::linux::lvms != undef {
    create_resources(soe::logical_volume, $soe::linux::lvms)
  }

# including this by default to clean up
#  if $set_facl == true {
    include common::facl::config
#  }

  if $tuned_enabled == true and $::operatingsystemmajrelease >= '7' {
    include common::tuned::config
  }

  if $include_qualys_agent == true {
    include common::qualys::agent
  }

  if $include_crowdstrike_falcon == true {
    include common::crowdstrike::falcon
  }

  if $hiera_class_includes == true {
    include common::hiera_include::classes
  }

  if $resolvconf_enabled == true {
    include common::resolv::resolvconf
  }
}
