
def hume_network_map(ip)
	case ip
		when /172.29.40.*/
			"customer-services"
		when /172.29.144.*/
			"device-management"
		when /172.29.177.*/
			"system-management"
		else
			nil
	end
end

mgmtPodNetworks = {'Global Switch' => '172.16.0.0/16',
			'Hume CDC' => '172.29.0.0/16',
			'Equinix Alex' => '172.18.0.0/16',
			'Port Melboune' => '172.21.0.0/16',
			'GovDC Unanderra' => '172.28.96.0/19',
			'GovDC Silverwater' => '172.28.64.0/19'
}

# Customer Env = glob, hume, port, silw, unan, alex
Facter.add(:customer_env) do
    confine :domain => /.*esbu.lab.com.au/
    setcode do
       case Facter.value('hostname')[0,4]
         when 'glob'
           site = 'Global Switch Ultimo'
         when 'hume'
           site = 'ACT Hume'
         when 'port'
           site = 'Port Melbourne'
         when 'silw'
           site = 'GovDC Silverwater'
         when 'unan'
           site = 'GovDC Unanderra'
         when 'alex'
           site = 'Equinix Alexandria'
         else
           nil
       end
    end
end

# Customer Tier = system-management, device-management, customer-services, unix, windows, storage
# TODO - Expand outside of Hume Mgmt Pod in future
Facter.add(:customer_tier) do
    confine :domain => /.*esbu.lab.com.au/
    # TODO - Restrict to Hume for now
    confine :network_eth0 => /172.29.*/
    setcode do
	ip_addr = Facter.value(:network_eth0)
        case ip_addr
		when /172.29.*/
			hume_network_map(ip_addr)
		else
			nil
	end
    end
end

# Customer App = graylog, elastic, foreman, frmnprxy, 
#		dhcp, util, influxdb, puppet, fipa, jump, repo, rhprox, swprx etc
Facter.add(:customer_app) do
    confine :domain => /.*esbu.lab.com.au/
    setcode do
       /(?:.{4})(?:caas)?(\D+)\d{2}/.match(Facter.value('hostname'))[1]
    end
end

# Customer Pool - PROD, NONP, LAB
Facter.add(:customer_pool) do
    confine :domain => /.*esbu.lab.com.au/
    setcode do
	    case /^(.+?)\./.match(Facter.value('domain'))[1]
        when 'nonp'
          pool = 'NONP'
        when 'lab'
          pool = 'LAB'
        when 'esbu'
          pool = 'PROD'
        else
          nil
       end
    end
end

# Customer Node Number = 01,02,03 ...
Facter.add(:customer_node_num) do
    confine :domain => /.*esbu.lab.com.au/
    setcode do
       /(?:\w+)([0-9]{2})/.match(Facter.value('hostname'))[1]
    end
end

# Infrastructure
Facter.add(:infrastructure) do
    confine :domain => /.*esbu.lab.com.au/
    setcode do
       case /(?:.{4})(?:caas)?(\D+)\d{2}/.match(Facter.value('hostname'))[1]
         when /dhcp|util|fipa|frmn|repo|jump|puppet|tftp|zprox|frmnprxy|swprx|rhprox|rhsat|swsat/
           infra = 'mgmt_pod'
         when /rancid/
           infra = 'networks'
         when /graylog|elastic|grafana|influxdb|gl2s/
           infra = 'logging'
         else
           nil
       end
    end
end

# Determine if disks are SSD or not

if Facter.value(:blockdevices) != nil
  Facter.value(:blockdevices).split(',').each do |device|
  	fact_name = "blockdevice_#{device}_is_ssd"
  	Facter.add(fact_name) do
  	  confine :domain => /.*esbu.lab.com.au/
   	  confine :kernel => 'Linux' 
  	  setcode do
  
        		if Facter::Core::Execution.exec("smartctl -i /dev/#{device} | grep Rotation | cut -f2 -d: | sed -e 's/^[[:space:]]*//'") == 'Solid State Device'
          		ssd = 'true'
  	        else
         			ssd = 'false'
        		end
  	  end
      	end
  end
end

# To check ESXi host, requires the guestinfo is set on the host
# Used by Elastic to determine if the data is segregated on the physical host layer
Facter.add(:esxi_host) do
  confine :domain => /.*esbu.lab.com.au/
  confine :virtual => /vmware/
  setcode do
    value = Facter::Core::Execution.exec("vmtoolsd --cmd='info-get guestinfo.physical_host' 2>&1")
    if value == 'No value found'
	value = nil
    end
    value
  end
end

