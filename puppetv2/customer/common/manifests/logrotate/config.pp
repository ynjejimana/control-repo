class common::logrotate::config {

  include ::logrotate

  $logdir_defaults = {
    ensure	=> directory,
  }

  $logrotate_logdirs = hiera_hash('common::logrotate::config::logrotate_logdirs', {})
  if $logrotate_logdirs {
    create_resources('file', $logrotate_logdirs, $logdir_defaults)
  }

  $logrotate_rules = hiera_hash('common::logrotate::config::logrotate_rules', {})
  if $logrotate_rules {
    create_resources('logrotate::rule', $logrotate_rules)
  }

}
