test_name "Windows Reboot Module - Reboot when Refreshed Explicit"
extend Puppet::Acceptance::Reboot

reboot_manifest = <<-MANIFEST
notify { 'step_1':
}
~>
reboot { 'now':
  when => refreshed
}
MANIFEST

confine :to, :platform => 'windows'

agents.each do |agent|
  step "Reboot when Refreshed (Explicit)"

  #Apply the manifest.
  on agent, puppet('apply', '--debug'), :stdin => reboot_manifest

  #Verify that a shutdown has been initiated and clear the pending shutdown.
  retry_shutdown_abort(agent)
end
