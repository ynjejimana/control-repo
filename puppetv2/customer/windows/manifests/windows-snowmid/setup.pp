class windows::windows-snowmid::setup (

  $instances		= [ ],
  $download_dir		= "${systemdrive}\\windows\\temp",
  $java_exe		= '',
  $snowmid_zip		= '',
  $pam_host		= '',
  $pam_token		= '',
  $cred_host		= '',
  $cred_host_port	= '443',
  $cred_auth_token	= '',
  $cred_host_ignore_ssl	= 'true',
  $cust_domains		= [],
  $use_proxy	        = false,
  $proxy_url		= '',
  $proxy_port		= '',

) {

  $instance_defaults  = {
    midzip_dir	  => $download_dir,
    snow_user	  => 'user',
    snow_password => 'password',
    threads_max	  => '10'
  }

  define mid_instance(
    $midzip_dir,
    $snow_user,
    $snow_password,
    $threads_max   = '10'
  ) {
    
    file { "${systemdrive}\\${hostname}_${name}":
      ensure	   => 'directory',
    } ->

    exec { "Unzip ${name} MID installer":
      command	   => "Expand-Archive -Path ${midzip_dir}\\latest.zip -DestinationPath ${systemdrive}\\${hostname}_${name} -Force", 
      onlyif	   => "if (test-path ${systemdrive}\\${hostname}_${name}\\agent) {exit 1}",
      provider	   => powershell,
    } ->

    file { "${systemdrive}\\${hostname}_${name}\\agent\\discovery_credentials.properties":
      content	   => regsubst(template('windows/windows-snowmid/discovery_credentials.properties.erb'), '\n', "\r\n", 'EMG'),
    } ->

    file { "${systemdrive}\\${hostname}_${name}\\config.xml.initial":
      content	   => template('windows/windows-snowmid/config.xml.erb'),
    } ~>

    exec { "Copy ${name} config.xml":
      command	   => "Copy-Item ${systemdrive}\\${hostname}_${name}\\config.xml.initial -Destination ${systemdrive}\\${hostname}_${name}\\agent\\config.xml -Force", 
      onlyif	   => "if (!((findstr \'mid_sys_id\' ${systemdrive}\\${hostname}_${name}\\agent\\config.xml) -match \'<parameter name=\"mid_sys_id\" value=\"\"/>\')) {exit 1}",
      refreshonly  => true,
      provider	   => powershell,
    } ~>

    exec { "Rename ${name} MID service":
      command	   => "(Get-Content \'${systemdrive}\\${hostname}_${name}\\agent\\conf\\wrapper-override.conf\').replace(\'wrapper.name=snc_mid\',\'wrapper.name=snc_mid_${hostname}_${name}\').replace(\'wrapper.displayname=ServiceNow MID Server\',\'wrapper.displayname=ServiceNow MID Server_${hostname}_${name}\') | Set-Content \'${systemdrive}\\${hostname}_${name}\\agent\\conf\\wrapper-override.conf\'",
      onlyif	   => "if (!((findstr \'wrapper.name=\' ${systemdrive}\\${hostname}_${name}\\agent\\conf\\wrapper-override.conf) -contains \'wrapper.name=snc_mid\')) {exit 1}",
      refreshonly  => true,
      provider	   => powershell,
    } ~>

    exec { "Start ${name} MID server":
      path	   => "$::path",
      command	   => "\$Env:path += \";\" + (Get-ChildItem -Path ${systemdrive}\\ -Recurse -Filter javapath -ErrorAction SilentlyContinue).FullName ; Start-Process \'${systemdrive}\\${hostname}_${name}\\agent\\bin\\mid.bat\' -ArgumentList \'start\'",
      provider	   => powershell,
      refreshonly  => true,
    } ->

    service { "snc_mid_${hostname}_${name}":
      enable	   => true,
      ensure	   => 'running', 
    }

  }

  exec { 'Download Java installer':
    command  => "(new-object System.Net.WebClient).DownloadFile(\'${java_exe}\',\'${download_dir}\\latest.exe\')",
    onlyif   => "if (test-path ${download_dir}\\latest.exe) {exit 1}",
    provider => powershell,
  } ->

  exec { 'Install JRE' :
    path     => "$::path",
    command  => "\$Env:TMP = \"${download_dir}\" ; Start-Process \'${download_dir}\\latest.exe\' -ArgumentList \'INSTALL_SILENT=1 AUTO_UPDATE=0 REBOOT=0 SPONSORS=0 REMOVEOUTOFDATEJRES=1\'",
    onlyif   => "if (\'${path}\' -Match \'java\') {exit 1}",
    provider => powershell,
    timeout  => 1800,
  } ->

  exec { 'Download MID installer':
    command  => "(new-object System.Net.WebClient).DownloadFile(\'${snowmid_zip}\',\'${download_dir}\\latest.zip\')",
    onlyif   => "if (test-path ${download_dir}\\latest.zip) {exit 1}",
    provider => powershell,
  }

  create_resources(windows::windows-snowmid::setup::mid_instance, $instances, $instance_defaults)

}
