class windows::windows-firewall::create {

$managed = hiera('windows::windows-firewall::create::managed','false')
$status = hiera('windows::windows-firewall::create::status','stopped')
$rules = hiera('windows::windows-firewall::create::rules',undef)

  if $managed == 'true' {
  
    if $status == "stopped" {
    
        exec { 'disablefirewall' :
             command  => '$(set-netfirewallprofile -all -enabled false)',
             provider => powershell,
             onlyif   => 'if ((get-netfirewallprofile -all).enabled -notcontains "true") { exit 1 }'
    
        }
    
    }
    
    else {
    
        exec { 'enablefirewall' :
             command  => '$(set-netfirewallprofile -all -enabled true)',
             provider => powershell,
             onlyif   => 'if ((get-netfirewallprofile -all).enabled -contains "true") { exit 1 }'
             }
    
        create_resources(windows::windows-firewall::fwrules, $rules)
    
        }
  }
}
