class windows::windows-oemagent::installagent ( 
  $OMSHost = '',
  $OMSHostIP = '',
  $installersourcepath = '',
  $installername = '',
  $agentregistrationpassword = '',
  $manage_oemagent = false,
)  {

  if $manage_oemagent == true {
    $tempsource = 'C:\build\oem'
    $servicename = 'Oracleagent12c1Agent'
    $oemagentdirectory = 'C:\oem\12.1.0.5.0_AgentCore_233\base'
    $emuploadport = hiera('windows::windows-oemagent::installagent::emuploadport','4900')

    exec { 'CopyOEMAgentSource' :
      path        =>  'C:\windows\system32',
      command     =>  "(md $tempsource) -and (cp ${installersourcepath}/*.* $tempsource)",
      onlyif      =>  "if ((test-path ${tempsource}/${installername}) -eq \$true) { exit 1}",
      provider    =>  powershell,
      logoutput   =>  on_failure,
      before      =>  Exec[UnzipOEMAgentSource],
    }

    exec { 'UnzipOEMAgentSource':
      path        =>  'C:\windows\system32',
      cwd         =>  "$tempsource",
      command     =>  "${tempsource}/unzip.exe -n ${installername} -d ${tempsource}",
      onlyif      =>  "if ((get-service $servicename -erroraction silentlycontinue) -ne \$null) { exit 1 }",
      provider    =>  powershell,
      logoutput   =>  on_failure,
      before      =>  Exec[ExecuteOEMAgentInstaller],
    }

    exec { 'ExecuteOEMAgentInstaller':
      path        =>  'C:\windows\system32',
      cwd         =>  "$tempsource",
      command     =>  "${tempsource}/agentdeploy.bat AGENT_BASE_DIR=${oemagentdirectory} OMS_HOST=${OMSHost} EM_UPLOAD_PORT=${emuploadport} AGENT_REGISTRATION_PASSWORD=${agentregistrationpassword}",
      onlyif      =>  "if ((get-service $servicename -erroraction silentlycontinue) -ne \$null) { exit 1 }",
      provider    =>  powershell,
      logoutput   =>  on_failure, 
    }
  } 
}
