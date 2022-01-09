# Configure the chrony service
class chrony::service (
  $config = $chrony::config,
  $service_ensure = $chrony::service_ensure,
  $service_name = $chrony::service_name) inherits chrony {

  service {
    'chrony':
      ensure     => $service_ensure,
      enable     => true,
      hasrestart => true,
      hasstatus  => true,
      name       => $service_name,
      subscribe  => File[$config]
  }

}
