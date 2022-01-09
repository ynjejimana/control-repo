class windows::windows-crowdstrike::falcon (
    $customer_id = '',
    $build_dir = 'C:\windows\temp',
    $manage_crowdstrike = false,
    $crowdstrike_installer = '',
    $https_proxy = 'https_proxy_ip.esbu.lab.com.au',
) {

  if $manage_crowdstrike == true {

    $proxy_port = hiera('proxy_port')
    $local_pkg_source = "$build_dir\\crowdstrikesensor.exe"

        exec { 'Download crowdstrike':
            command => "(new-object System.Net.WebClient).DownloadFile('$crowdstrike_installer','$local_pkg_source')",
            onlyif => "if ((test-path $local_pkg_source) -eq \$true) {exit 1}",
            provider => powershell,
            before => Package['CrowdStrike Windows Sensor'],
        } ->

        # Install and configure Falcon sensor
        package { 'CrowdStrike Windows Sensor':
            ensure  => installed,
            source => $local_pkg_source,
            install_options => ['/install', '/quiet', '/norestart', "CID=${customer_id}", "APP_PROXYNAME=${https_proxy}", "APP_PROXYPORT=${proxy_port}"],
            provider => windows,
        } ->

        service { 'CSFalconService':
            ensure => running,
            enable => true,
        }
    }
  
}
