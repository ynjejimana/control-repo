# Add all the perameters needed for the chrony class
class chrony::params {
  $chrony_password    = 'MaleMermaid348'
  $commandkey         = 0
  $config             = '/etc/chrony.conf'
  $config_keys        = '/etc/chrony.keys'
  $config_keys_group  = chrony
  $config_keys_manage = true
  $config_keys_mode   = '0640'
  $config_keys_owner  = 'root'
  $keys               = []
  $lock_all           = false
  $mailonchange       = undef
  $package_ensure     = 'present'
  $package_name       = 'chrony'
  $port               = 0
  $queryhosts         = []
  $refclocks          = []
  $servers            = {
    '0.au.pool.ntp.org' => ['iburst'],
    '1.au.pool.ntp.org' => ['iburst'],
    '2.au.pool.ntp.org' => ['iburst'],
    '0.au.pool.ntp.org' => ['iburst']
  }
  $service_ensure     = 'running'
  $service_name       = 'chronyd'
  $threshold          = 0.5

}
