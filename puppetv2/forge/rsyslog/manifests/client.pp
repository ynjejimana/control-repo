# == Class: rsyslog::client
#
# Full description of class role here.
#
# === Parameters
#
# [*log_remote*]
# [*spool_size*]
# [*spool_timeoutenqueue*]
# [*remote_type*]
# [*remote_forward_format*]
# [*log_local*]
# [*log_auth_local*]
# [*listen_localhost*]
# [*custom_config*]
# [*custom_params*]
# [*server*]
# [*port*]
# [*remote_servers*]
# [*ssl_ca*]
# [*log_templates*]
# [*actionfiletemplate*]
# [*rate_limit_burst*]
# [*rate_limit_interval*]
#
# === Variables
#
# === Examples
#
#  class { 'rsyslog::client': }
#
class rsyslog::client (
  $log_remote     	             = true,
  $spool_size        	         = '1g',
  $remote_type           	     = 'tcp',
  $rebind_every                  = undef,
  $action_queue_size             = false,
  $action_queue_discard_mark     = false,
  $action_queue_discard_severity = false,
  $spool_timeoutenqueue          = false,
  $action_queue_low_water_mark   = false,
  $action_queue_high_water_mark  = false,
  $remote_forward_format         = 'RSYSLOG_ForwardFormat',
  $log_local                     = false,
  $log_auth_local                = false,
  $listen_localhost              = false,
  $custom_config                 = undef,
  $custom_params                 = undef,
  $server                        = 'log',
  $port                          = '514',
  $remote_servers                = false,
  $ssl_ca                        = undef,
  $log_templates                 = false,
  $enable_pstats                 = false,
  $pstat_interval                = 300,
  $pstat_facility                = 5,
  $pstat_severity                = 6,
  $actionfiletemplate            = false,
  $high_precision_timestamps     = false,
  $rate_limit_burst              = undef,
  $rate_limit_interval           = undef,
  $additional_snippets	         = undef,
) inherits rsyslog {

  if $custom_config {
    $content_real = template($custom_config)
  } else {
    $content_real = template("${module_name}/client.conf.erb")
  }

  rsyslog::snippet { $rsyslog::client_conf:
    ensure  => present,
    content => $content_real,
  }

  if $additional_snippets != undef {
    create_resources(rsyslog::snippet, $additional_snippets)
  }

  if $rsyslog::ssl and $ssl_ca == undef {
    fail('You need to define $ssl_ca in order to use SSL.')
  }

  if $rsyslog::ssl and $remote_type != 'tcp' {
    fail('You need to enable tcp in order to use SSL.')
  }

}
