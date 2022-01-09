class common::os_hardening::install (
	$protected_packages = [],
){

  class { 'os_hardening':
  	protected_packages => $protected_packages,
  }

}
