class common::clamav::agent::install (
) inherits common::clamav::agent {

  package { $pkgs:
    ensure                  => 'latest',
  } ->
  file { "/etc/freshclam.conf":
    content                 => template('common/clamav/agent_freshclam_conf.erb'),
    mode                    => 0600,
    owner                   => 'root',
    group                   => 'root',
    selinux_ignore_defaults => true,
  } ->
  file { $freshclamUpdateLogFile:
    mode                    => 0644,
    owner                   => $freshclamUser,
    group                   => $freshclamUser,
    ensure                  => 'present',
  } ->
  file { $files2remove:
    ensure                  => 'absent',
  } ->
  file { '/usr/local/bin/freshclam.sh':
    content                 => template('common/clamav/agent_freshclam_cron.erb'),
    mode                    => 0755,
    owner                   => 'root',
    group                   => 'root',
    selinux_ignore_defaults => true,
  } ->
  selinux::boolean { $clamSELinuxConfig:
    ensure                    => 'on',
  } 

  include common::clamav::agent::scan
}

