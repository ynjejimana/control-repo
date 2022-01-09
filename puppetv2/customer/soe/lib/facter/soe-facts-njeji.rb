# NJeJI Environment Fact
# Customer Env - NONP Services-Specific 
Facter.add(:customer_env) do
    confine :domain => /.*elab.gov.au/
    confine :network_eth0 => /10.18.240.*/
    has_weight 100
    setcode do
       env = 'svc'
    end
end
# Long Customer Env - NONP Services-Specific
Facter.add(:customer_env_long) do
    confine :domain => /.*elab.gov.au/
    confine :network_eth0 => /10.18.240.*/
    has_weight 100
    setcode do
        env = 'svc'
    end
end
# Customer Env = pft, dvg, pdc, sdc
Facter.add(:customer_env) do
    confine :domain => /.*elab.gov.au/
    setcode do
       env = Facter.value('hostname')[3,3]
    end
end
# Long Customer Env = dvg becomes devg for instance. This is used to map the mountpoints correctly
Facter.add(:customer_env_long) do
    confine :domain => /.*elab.gov.au/
    setcode do
        env = Facter.value('hostname')[3,3]
	case env
		when /dv./
			env = env.gsub(/dv/,'dev')	
		when /pfa/
			env = env.gsub(/fa/,'erf')
		when /sv./
			env = env.gsub(/sv/,'svt')
		else
			env = env
	end
    end
end
# Customer Tier = ws, as, db
Facter.add(:customer_tier) do
    confine :domain => /.*elab.gov.au/
    setcode do
       tier = Facter.value('hostname')[6,2]
    end
end
# Customer App = OHS, OHT...
Facter.add(:customer_app) do
    confine :domain => /.*elab.gov.au/
    setcode do
       app = Facter.value('hostname')[8,3]
    end
end
# Customer Pool - PROD, NONP
Facter.add(:customer_pool) do
    confine :domain => /.*elab.gov.au/
    setcode do
	case Facter.value('hostname')[3,3]
		when 'pdc', 'sdc'
			pool = 'PROD'
		else
			pool = 'NONP' 
	end
    end
end
# Customer Node Number = 1,2,3 ...
Facter.add(:customer_node_num) do
    confine :domain => /.*elab.gov.au/
    setcode do
       app = Facter.value('hostname')[12,1]
    end
end
# Customer child environment - DEV, TST. 
Facter.add(:customer_child_env) do
    confine :kernel => :windows
    confine :domain => /.*elab.gov.au/
    confine :network_ethernet => /10.18.*/
    ps_cmd   = Facter::Util::Resolution.exec("C:\\Windows\\system32\\WindowsPowershell\\v1.0\\powershell.exe -command \"test-path c:\\build\\test.env\"")
    setcode do
      case ps_cmd
        when 'True'
          answer='test'
        else
          answer='dev'
        end
    end
end
