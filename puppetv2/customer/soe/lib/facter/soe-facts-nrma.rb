# Customer name = goe=Group Operating Environment
Facter.add(:customer_name) do
    confine :domain do |dom|
        [ 'group.mynrlab.com', 'nrlabsx.com.au' ].include? dom
    end
    setcode do
       case Facter.value('hostname')[0,3]
         when 'goe'
           name = 'goe'
         else
           nil
       end
    end
end

# Customer Env: d=dev, s=sit, u=uat, n=nft, t=production support, p=production, g=training
Facter.add(:customer_env) do
    confine :domain do |dom|
        [ 'group.mynrlab.com', 'nrlabsx.com.au' ].include? dom
    end
    setcode do
       case Facter.value('hostname')[3,1]
         when 'd'
           env = 'dev'
         when 's'
           env = 'sit'
         when 'u'
           env = 'uat'
         when 'f'
           env = 'nft'
         when 't'
           env = 'psp'
         when 'p'
           env = 'prd'
         when 'g'
           env = 'trn'
         else
           nil
       end
    end
end

# Customer App: i=idm, e=ebs, s=soa .....
Facter.add(:customer_app) do
    confine :domain do |dom|
        [ 'group.mynrlab.com', 'nrlabsx.com.au' ].include? dom
    end
    setcode do
       case Facter.value('hostname')[4,1]
         when 'i'
           app = 'idm'
         when 'e'
           app = 'ebs'
         when 's'
           app = 'soa'
         when 'c'
           app = 'sbl'
         when 'm'
           app = 'hub'
         when 'u'
           app = 'odi'
         when 'q'
           app = 'qas'
         when 'a'
           app = 'anl'
         else
           nil
       end
    end
end

# Customer tier: mz=dmz, wb=web, as=app, db=db .....
Facter.add(:customer_tier) do
    confine :domain do |dom|
        [ 'group.mynrlab.com', 'nrlabsx.com.au' ].include? dom
    end
    setcode do
       case Facter.value('hostname')[5,2]
         when 'mz'
           tier = 'dmz'
         when 'wb'
           tier = 'web'
         when 'as'
           tier = 'app'
         when 'db'
           tier = 'db'
         else
           nil
       end
    end
end

# Customer Node Number = 01,02,03 ...
Facter.add(:customer_node_num) do
    confine :domain do |dom|
        [ 'group.mynrlab.com', 'nrlabsx.com.au' ].include? dom
    end
    setcode do
       /(?:\w+)([0-9]{2})/.match(Facter.value('hostname'))[1]
    end
end

