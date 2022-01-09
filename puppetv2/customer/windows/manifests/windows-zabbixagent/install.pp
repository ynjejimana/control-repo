class windows::windows-zabbixagent::install (
  $zabbixinstaller = hiera('windows::windows-zabbixagent::install::zabbixinstaller','\\\\172.16.40.21\\repo\\windows\\zabbix\\zabbix_agents_3.4.6\\bin\\win64'),
  $enablezabbixinstaller = hiera('windows::windows-zabbixagent::install::enablezabbixinstaller',true)
) {

  unless $enablezabbixinstaller == false {

    $zabbixproxies = hiera('common::zabbix30::agent::server',undef)
    $Server = join($zabbixproxies, ',')
    $LogFile = hiera('windows::windows-zabbixagent::install::LogFile','C:\Program Files\Zabbix Agent\Zabbix_agentd.log')
    $Hostname = $::hostname
    $ListenPort = hiera('windows::windows-zabbixagent::install::ListenPort','10050')
    $StartAgents = hiera('windows::windows-zabbixagent::install::StartAgents','5')
    $EnableRemoteCommands = hiera('windows::windows-zabbixagent::install::EnableRemoteCommands','0')
    $DebugLevel = hiera('windows::windows-zabbixagent::install::DebugLevel','0')

    file { 'C:\Program Files\Zabbix Agent':
      ensure             =>  directory,
      path               =>  'C:\Program Files\Zabbix Agent',
      source             =>  $zabbixinstaller,
      source_permissions =>  ignore,
      recurse            =>  remote,
      notify             =>  Service['Zabbix Agent'],
    }

    -> file { 'C:\Program Files\Zabbix Agent\zabbix_agentd.conf' :
        ensure  =>  present,
        content =>  template('windows/windows-zabbixagent/zabbix_agentd.conf.erb'),
        path    =>  'C:\Program Files\Zabbix Agent\zabbix_agentd.conf',
        notify  =>  Service['Zabbix Agent'],
    }

    -> exec { 'InstallService' :
        path     =>  'C:\Program Files\Zabbix Agent',
        cwd      =>  'C:\Program Files\Zabbix Agent',
        command  =>  'C:\"Program Files"\"Zabbix Agent"\zabbix_agentd.exe --config "C:\Program Files\Zabbix Agent\zabbix_agentd.conf" --install',
        onlyif   =>  'if ( (get-service "zabbix agent" -erroraction silentlycontinue).name -ne $null) {exit 1}',
        provider =>  powershell,
    }

    -> service { 'Zabbix Agent' :
        ensure  =>  running,
        require =>  Exec['InstallService'],
    }

  }

}
