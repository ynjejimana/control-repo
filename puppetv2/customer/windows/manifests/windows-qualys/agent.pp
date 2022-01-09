class windows::windows-qualys::agent (
    $activation_id = hiera('common::qualys::agent::activation_id'),
    $customer_id = hiera('common::qualys::agent::customer_id'),
    $qualys_pkg_sourcedir = '',
    $qualys_pkg_name = 'QualysCloudAgent.exe',
    $qualys_software_name = 'Qualys Cloud Security Agent',
    $qualys_pkg_ensure = 'installed',
    $proxy_param_record_file = 'C:\Program Files\Qualys\QualysAgent\QualysCloudAgentPuppetClassProxyParams.txt',
    $proxy_configure_script = 'C:\Progra~1\Qualys\QualysAgent\QualysProxy.exe',
    $https_proxy = 'https_proxy_ip.esbu.lab.com.au',
    $service_name = 'QualysAgent',
    $manage_qualys = false,
) {

  if $manage_qualys == true {

    $proxy_port = hiera('proxy_port')

    if $qualys_pkg_ensure == 'absent' {

        # Remove the Qualys agent and all files
        exec { 'Uninstall Qualys':
            command => 'c:\progra~1\qualys\qualysagent\uninstall.exe uninstall=True force=True',
            onlyif => 'c:\windows\system32\sc.exe query qualysagent',
            provider => windows,
        }

    } else {

        # Install and configure Qualys agent

        $qualys_source = "$qualys_pkg_sourcedir\\$qualys_pkg_name"
        $local_source_dir = 'C:\windows\temp'
        $local_pkg_source = "$local_source_dir\\$qualys_pkg_name"

        exec { 'Download Qualys':
            command => "(new-object System.Net.WebClient).DownloadFile('$qualys_source','$local_pkg_source')",
            onlyif => "if ((test-path $local_pkg_source) -eq \$true) {exit 1}",
            provider => powershell,
        } ->

        package { $qualys_software_name :
            ensure  => $qualys_pkg_ensure,
            source => $local_pkg_source,
            install_options => ["CustomerId={$customer_id}", "ActivationId={$activation_id}"],
            provider => windows,
        } ->

        file { $proxy_param_record_file :
            ensure => present,
            content => template('windows/windows-qualys/proxy_param_record_file.erb'),
        } ->

        exec { 'configure-proxy' :
            command => "$proxy_configure_script /u http://$https_proxy:$proxy_port",
            subscribe => File["$proxy_param_record_file"],
            refreshonly => true,
        } ->

        service { $service_name :
            ensure => running,
            enable => true,
        }

    }
  }
}
