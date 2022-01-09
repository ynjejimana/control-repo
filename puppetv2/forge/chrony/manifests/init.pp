# NTT Chrony class puppetv2
class chrony (
  $commandkey           = $chrony::params::commandkey,
  $config               = $chrony::params::config,
  $config_keys          = $chrony::params::config_keys,
  $chrony_password      = $chrony::params::chrony_password,
  $config_keys_owner    = $chrony::params::config_keys_owner,
  $config_keys_group    = $chrony::params::config_keys_group,
  $config_keys_mode     = $chrony::params::config_keys_mode,
  $config_keys_manage   = $chrony::params::config_keys_manage,
  $keys                 = $chrony::params::keys,
  $package_ensure       = $chrony::params::package_ensure,
  $package_name         = $chrony::params::package_name,
  $refclocks            = $chrony::params::refclocks,
  $servers              = $chrony::params::servers,
  $service_ensure       = $chrony::params::service_ensure,
  $service_name         = $chrony::params::service_name,
  $queryhosts           = $chrony::params::queryhosts,
  $mailonchange         = $chrony::params::mailonchange,
  $threshold            = $chrony::params::threshold,
  $lock_all             = $chrony::params::lock_all,
  $port                 = $chrony::params::port) inherits chrony::params {

  if ! $config_keys_manage and $chrony_password != 'unset'  {
    fail("Setting \$config_keys_manage false and \$chrony_password at same time in ${module_name} is not possible.")
  }

  class { '::chrony::install': }
  -> class { '::chrony::config': }
  ~> class { '::chrony::service': }
  -> Class['::chrony']

}
