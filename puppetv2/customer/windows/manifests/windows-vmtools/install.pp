class windows::windows-vmtools::install (
  $vmtools_package = hiera('windows::windows-vmtools::install::vmtools_package','\\\\172.21.40.21\\repo\\windows\\vmtools\\VMware-tools-9.0.15-2560490-x86_64.exe'),
  $enablevmtools = hiera('windows::windows-vmtools::install::enablevmtools',true)
) {

  unless $enablevmtools == false {

    if $::virtual == 'vmware' and $::osfamily == 'Windows' {
      # Install VMWareTools
      package { 'VMware Tools':
        ensure          => installed,
        source          => $vmtools_package,
        provider        => windows,
        install_options => ['/s','/v',"/qn reboot=r"]
      }

      service { 'VMTools' :
        ensure => running,
      }
    }

  }

}
