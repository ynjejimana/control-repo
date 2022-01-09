# Class common::ipaddr::config
#
# This puppet module configures the files that configure IP addresses.
# Written for Cloudforms IP address changing during the build of the machine.
#
class common::ipaddr::config (
        $cust_ip        = $::cust_next_ip,
        $cust_mask      = $::cust_next_mask,
        $cust_gw        = $::cust_next_gw,
        $cust_mac       = $::cust_mac,
        $bkp_ip         = $::bkp_next_ip,
        $bkp_mac        = $::bkp_mac,
        $mgmt_ip        = $::mgmt_next_ip,
        $mgmt_mac       = $::mgmt_mac,
) {

        file { "/etc/sysconfig/network":
                ensure  => file,
                mode    => '0644',
                owner   => 'root',
                group   => 'root',
                content => template("common/ipaddr/network.erb"),
        }

        file { "/etc/sysctl.conf":
                ensure  => file,
                mode    => '0644',
                owner   => 'root',
                group   => 'root',
                content => template("common/ipaddr/sysctl_conf.erb"),
        }

        $interface_temp = $::interfaces
        $split_interface = split($interface_temp, ',')
        $cust_interface = $split_interface[0]
        $mgmt_interface = $split_interface[1]
        $bkp_interface = $split_interface[2]

        file { "/etc/sysconfig/network-scripts/ifcfg-${cust_interface}":
                ensure  => file,
                mode    => '0644',
                owner   => 'root',
                group   => 'root',
                content => template("common/ipaddr/cust_interface.erb"),
        }
        
	file { "/etc/sysconfig/network-scripts/ifcfg-${mgmt_interface}":
                ensure  => file,
                mode    => '0644',
                owner   => 'root',
                group   => 'root',
                content => template("common/ipaddr/mgmt_interface.erb"),
        }
	
        file { "/etc/sysconfig/network-scripts/ifcfg-${bkp_interface}":
                ensure  => file,
                mode    => '0644',
                owner   => 'root',
                group   => 'root',
                content => template("common/ipaddr/bkp_interface.erb"),
        }
}
