class windows::windows-winlogbeat::install (
  $winlogbeatinstaller          = undef,
  $installwinlogbeat            = false,
  $install_dir                  = 'C:\Program Files\winlogbeat',
  $winlogbeat_servicename       = 'winlogbeat',
  $winlogbeat_eventlogs         = {},
  $winlogbeat_outputs           = {},
  $winlogbeat_logtofiles        = true,
  $winlogbeat_loglevel          = info,
  $winlogbeat_logfile           = 'winlogbeat.log',
  $winlogbeat_logbytes          = 20971520,
  $winlogbeat_loggingkeepfiles  = 24,
  $winlogbeat_cafilecontents    = hiera('common::filebeat::client::filebeat_cafilecontents',undef),
) {

  if $installwinlogbeat == true {

   $winlogbeat_configfile  = "${install_dir}\\winlogbeat.yml"
   $winlogbeat_logdir      = "${install_dir}\\logs"
   $winlogbeat_cafile      = "${install_dir}\\ca.crt"

   file { $install_dir:
     ensure  => directory,
     before  => Exec['Download winlogbeat'],
   } ->

   exec { 'Download winlogbeat':
     command    => "(new-object System.Net.WebClient).DownloadFile('$winlogbeatinstaller','${install_dir}\\winlogbeat.exe')",
     onlyif     => "if ((test-path '${install_dir}\\winlogbeat.exe') -eq \$true) {exit 1}",
     provider   => powershell,
   } ->

   file { $winlogbeat_cafile:
      ensure   => file,
      content  => $winlogbeat_cafilecontents,
   } ->

   file { $winlogbeat_configfile:
      ensure  => file,
      content  => template('windows/windows-winlogbeat/winlogbeat.yml.erb'),
   } ->

    exec { 'Setup winlogbeat service':
      command  => "new-service -name ${winlogbeat_servicename} -binarypathname '\"${install_dir}\\winlogbeat.exe\" -c \"${install_dir}\\winlogbeat.yml\"'",
      onlyif   => "if ( (get-service ${winlogbeat_servicename} -erroraction silentlycontinue).name -ne \$null) {exit 1}",
      provider => powershell,
    } ->

    service { $winlogbeat_servicename:
      ensure      => running,
      enable      => true,
      hasrestart  => true,
      require     => Exec['Setup winlogbeat service'],
      subscribe   => File[$winlogbeat_configfile], 
    }
  }
}
