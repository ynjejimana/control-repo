# NJeJI Environment Fact
# Customer Env - PROD, DR, DEV, QA
# See also customer_pool
Facter.add(:customer_env) do
    confine :network_eth0 do |value|
	case value
		when /10.197.22[456].*/, /10.197.19[234].*/
			true
		else
			false
	end
    end
    confine :domain => /.*esbu.lab.com.au/
    setcode do
        env = Facter.value('hostname')[6,4]
	case env
		when /qa../
			env = 'qa'
		when /dr../
			env = 'dr'
		when /dev./
			env = 'dev'
		when /prod/
			env = 'prod'
		else
			env = env
	end
    end
end
# This doesnt make sense for AESG
# Customer Tier = 
#Facter.add(:customer_tier) do
#    confine :network_eth0 => /10.197.22[45].*/
#    confine :domain => /.*esbu.lab.com.au/
#    setcode do
#       tier = Facter.value('hostname')[2,4]
#    end
#end

# AESG dont really follow a pattern of teir+app so we're folding everything into customer_app
# Customer App = boba, bpca, bpcs, disp...
Facter.add(:customer_app) do
    confine :network_eth0 do |value|
	case value
		when /10.197.22[456].*/, /10.197.19[234].*/
			true
		else
			false
	end
    end
    confine :domain => /.*esbu.lab.com.au/
    setcode do
       app = Facter.value('hostname')[2,4]
    end
end
# Customer Pool - PROD, NONP
# Pool differs from environment as it groups Prod+DR into the PROD pool etc.
Facter.add(:customer_pool) do
    confine :network_eth0 do |value|
	case value
		when /10.197.22[456].*/, /10.197.19[234].*/
			true
		else
			false
	end
    end
    confine :domain => /.*esbu.lab.com.au/
    setcode do
	case Facter.value('hostname')[6,4]
		when /dev./, /qa../
			pool = 'NONP'
		when 'prod', /dr../
			pool = 'PROD'
		else
			pool = 'UNKNOWN' 
	end
    end
end
# Customer Node Number = 1,2,3 ...
# AESG node names are non standard this wont work
#Facter.add(:customer_node_num) do
#    confine :network_eth0 => /10.197.22[45].*/
#    confine :domain => /.*esbu.lab.com.au/
#    setcode do
#       app = Facter.value('hostname')[12,1]
#    end
#end
