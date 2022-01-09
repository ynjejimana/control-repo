# FinastraCBA Environment Fact
# Customer Env = prd, uat, dev, dre
Facter.add(:customer_env) do
    confine :domain => /.*cba.finastra.local/
    setcode do
       env = Facter.value('hostname')[5,3]
    end
end
# Customer App = ESS,LIQ,AMQ ...
Facter.add(:customer_app) do
    confine :domain => /.*cba.finastra.local/
    setcode do
       app = Facter.value('hostname')[8,3]
    end
end
# Customer Node Number = 1,2,3 ...
Facter.add(:customer_node_num) do
    confine :domain => /.*cba.finastra.local/
    setcode do
       app = Facter.value('hostname')[11,2]
    end
end
# Customer Pool - The customer has 3x phyiscally seperated environments
# prod, dr, nonp
# The only element we can use to identify them is via their IP range

Facter.add(:customer_pool) do
    confine :domain => /.*cba.finastra.local/
    setcode do
       pool = Facter.value('ipaddress')
    case pool
      when /192.168.100.*/
        pool = 'prod'
      when /192.168.105.*/
        pool = 'prod'
      when /192.168.106.*/
        pool = 'prod'
      when /192.168.110.*/
        pool = 'prod'
      when /192.168.111.*/
        pool = 'prod'
      when /192.168.112.*/
        pool = 'prod'
      when /192.168.250.*/
        pool = 'prod'
      when /192.168.150.*/
        pool = 'dr'
      when /192.168.50.*/
        pool = 'dr'
      when /192.168.51.*/
        pool = 'dr'
      when /192.168.52.*/
        pool = 'dr'
      when /192.168.90.*/
        pool = 'dr'
      when /192.168.101.*/
        pool = 'nonp'
      when /192.168.102.*/
        pool = 'nonp'
      when /192.168.103.*/
        pool = 'nonp'
      when /192.168.104.*/
        pool = 'nonp'
      when /192.168.115.*/
        pool = 'nonp'
      when /192.168.116.*/
        pool = 'nonp'
      when /192.168.251.*/
        pool = 'nonp'
      end
    end
end

