# Configure the chrony daemon
class chrony::config (
  $commandkey           = $chrony::commandkey,
  $config               = $chrony::config,
  $config_keys          = $chrony::config_keys,
  $config_keys_owner    = $chrony::config_keys_owner,
  $config_keys_group    = $chrony::config_keys_group,
  $config_keys_mode     = $chrony::config_keys_mode,
  $config_keys_manage   = $chrony::config_keys_manage,
  $chrony_password      = $chrony::chrony_password,
  $keys                 = $chrony::keys,
  $refclocks            = $chrony::refclocks,
  $mailonchange         = $chrony::mailonchange,
  $threshold            = $chrony::threshold,
  $lock_all             = $chrony::lock_all,
  $servers              = $chrony::servers,) inherits chrony {

  file {
    $config:
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('chrony/chrony.conf.erb');
    $config_keys:
      ensure  => file,
      replace => $config_keys_manage,
      owner   => $config_keys_owner,
      group   => $config_keys_group,
      mode    => $config_keys_mode,
      content => template('chrony/chrony.keys.erb'),
  }

}
