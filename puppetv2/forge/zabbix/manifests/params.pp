class zabbix::params {

  $user = "zabbix"
  $group = "zabbix"

  $config_dir = "/etc/zabbix"
  $user_home_dir = "/var/lib/zabbix"
  $log_dir = "/var/log/zabbix"
  
  #added by Jephe for include parameter
  $agent_include_dir = "${config_dir}/zabbix_agentd"
  $agent_include_dir_extra = []
  $proxy_include_dir = "${config_dir}/zabbix_proxy"
  # end

  #added by Jephe for Zabbix 1.8
  $zabbix_log_dir = "/var/log/zabbix"
  $zabbix_pid_dir = "/var/run/zabbix"
  $zabbix_sqlitedb_file = "/tmp/zabbix_proxy.db"
  # end 

  $enable_remote_commands = 0
  
  $pid_dir = "/var/run/zabbix"
 
  $agent_service_name = "zabbix-agent"
  $agent_package_name = "zabbix-agent"
  
  $proxy_service_name = "zabbix-proxy"
  $proxy_package_name = "zabbix-proxy"

  $server_service_name = "zabbix-server"
  $server_package_name = "zabbix-server"

  $userparameter_config_dir = "/etc/zabbix/zabbix_agentd"
  $agentd_conf = "${config_dir}/zabbix_agentd.conf"

}
