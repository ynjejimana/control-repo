require 'facter'

Facter.add(:interface_primary) do
  confine :kernel => :linux
  setcode do
    osid = Facter.value(:operatingsystem)
    case osid
    when /CentOS|RedHat|OracleLinux|SuSE/
      result = Facter::Util::Resolution.exec("cat /proc/net/route | awk '{print $1,$2}' | grep 00000000 | awk '{print $1}'")
    end
  end
end

Facter.add(:ip_primary) do
  confine :kernel => :linux
  setcode do
    osid = Facter.value(:operatingsystem)
    case osid
    when /CentOS|RedHat|OracleLinux|SuSE/
      if_primary = Facter.value(:interface_primary)
      result = Facter.value("ipaddress_#{if_primary}")
    end
  end
end

Facter.add(:network_primary) do
  confine :kernel => :linux
  setcode do
    osid = Facter.value(:operatingsystem)
    case osid
    when /CentOS|RedHat|OracleLinux|SuSE/
      if_primary = Facter.value(:interface_primary)
      result = Facter.value("network_#{if_primary}")
    end
  end
end

Facter.add(:netmask_primary) do
  confine :kernel => :linux
  setcode do
    osid = Facter.value(:operatingsystem)
    case osid
    when /CentOS|RedHat|OracleLinux|SuSE/
      if_primary = Facter.value(:interface_primary)
      result = Facter.value("netmask_#{if_primary}")
    end
  end
end
