Facter.add("activationstatus") do
    confine :kernel => :windows
    ps_cmd   = Facter::Util::Resolution.exec("C:\\Windows\\system32\\WindowsPowershell\\v1.0\\powershell.exe -command \"(Get-CimInstance -Class SoftwareLicensingProduct |Where {$_.ApplicationID -eq '55c92734-d682-4d71-983e-d6ec3f16059f' -AND $_.PartialProductKey -ne $null}).licensestatus\"")
    setcode do
      case ps_cmd
        when '1'
          answer='activated'
        else
          answer='inactive'
        end
    end
end
Facter.add("dnsservers") do
    confine :kernel => :windows
    setcode do
      Facter::Util::Resolution.exec("C:\\Windows\\system32\\WindowsPowershell\\v1.0\\powershell.exe -command \"(Get-wmiobject -class win32_networkadapterconfiguration | where {$_.defaultipgateway -ne $null}).dnsserversearchorder\" -join ','")
    end
end
Facter.add("domainrole") do
    confine :kernel => :windows
    ps_cmd   = Facter::Util::Resolution.exec("C:\\Windows\\system32\\WindowsPowershell\\v1.0\\powershell.exe -command \"(Get-wmiobject -class win32_computersystem).domainrole")
    setcode do
      case ps_cmd
        when '0'
          answer='Standalone Workstation'
        when '1'
          answer='Member Workstation'
        when '2'
          answer='Standalone Server'
        when '3'
          answer='Member Server'
        when '4'
          answer='Backup Domain Controller'
        when '5'
          answer='Primary Domain Controller'
        end
    end
end
Facter.add('edition') do
    confine :kernel => :windows
    setcode do
        require 'facter/util/wmi'
        Facter::Util::WMI.execquery("SELECT Caption FROM Win32_OperatingSystem").each do |os|
            Edition = os.Caption
            break
        end
        Edition
    end
end
Facter.add("powershell_version") do
    confine :kernel => :windows
    setcode do
        Facter::Util::Resolution.exec("C:\\Windows\\system32\\WindowsPowershell\\v1.0\\powershell.exe -command \"(Get-Host).Version.Major\"")
    end
end
Facter.add('domainJoined') do
  confine :osfamily => :windows
  setcode do
    begin
      require 'win32ole'
      wmi = WIN32OLE.connect("winmgmts:\\\\.\\root\\cimv2")
      compSystem = wmi.ExecQuery("SELECT * FROM Win32_ComputerSystem").each.first
      compSystem.PartOfDomain.to_s
    end
  end
end
Facter.add('systemDrive') do
  confine :osfamily => :windows
  setcode do
    begin
      require 'win32ole'
      wmi = WIN32OLE.connect("winmgmts:\\\\.\\root\\cimv2")
      compSystem = wmi.ExecQuery("SELECT * FROM Win32_OperatingSystem").each.first
      compSystem.SystemDrive.to_s
    end
  end
end