require 'facter'


Facter.add(:is_spacewalk_client_registered) do
        confine :kernel => :linux
        setcode do
                osid = Facter.value(:operatingsystem)
                case osid
                when /CentOS|RedHat|OracleLinux/
                        result = Facter::Util::Resolution.exec("test -f /etc/sysconfig/rhn/systemid; echo $?")
                when /SuSE/
                        result = Facter::Util::Resolution.exec("test -f /etc/sysconfig/rhn/somethingelse; echo $?")
                end
        end
end
