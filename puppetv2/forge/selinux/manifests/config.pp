# Class: selinux::config
#
# Description
#  This class is designed to configure the system to use SELinux on the system
#
# Parameters:
#  - $mode (enforced|permissive|disabled) - sets the operating state for SELinux.
#
# Actions:
#  Configures SELinux to a specific state (enforced|permissive|disabled)
#
# Requires:
#  This module has no requirements
#
# Sample Usage:
#  This module should not be called directly.
#
class selinux::config(
  $mode
) {
  Exec {
    path => '/bin:/sbin:/usr/bin:/usr/sbin',
  }

  $config_file = '/etc/selinux/config'

  file { $selinux::params::sx_mod_dir:
    ensure => directory,
  }

  # Check to see if the mode set is valid.
  if $mode == 'enforcing' or $mode == 'permissive' or $mode == 'disabled' {
    file { $config_file :
      ensure  => file,
      owner   => root,
      group   => root,
      content => "SELINUX=${mode}\nSELINUXTYPE=targeted\n",
    }

    case $mode {
      permissive,disabled: {
        $sestatus = '0'
        if $mode == 'disabled' and $::selinux_current_mode == 'permissive' {
          notice('A reboot is required to fully disable SELinux. SELinux will operate in Permissive mode until a reboot')
        }
      }
      enforcing: {
        $sestatus = '1'
      }
      default : {
        fail('You must specify a mode (enforced, permissive, or disabled) for selinux operation')
      }
    }

    if $::osfamily == "RedHat" {
      $mountpoint = $::operatingsystemmajrelease ? {
        "6" => "/selinux",
        "7" => "/sys/fs/selinux",
        default => "/selinux",
      }
    }

    exec { "change-selinux-status-to-${mode}":
      command => "echo ${sestatus} > ${mountpoint}/enforce",
      unless  => "grep -q '${sestatus}' ${mountpoint}/enforce",
    }

  } else {
    fail("Invalid mode specified for SELinux: ${mode}")
  }
}
