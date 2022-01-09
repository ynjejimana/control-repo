# Unmanaged SOE linux class that includes the bare minimum required classes for an unmanaged system.
# This class was created to cater for Cloudforms VMs which do an initial puppet run to configure
# the VM, but then do not run puppet from then on.
# Do not modify this class without extensively testing the additions as it is deployed enterprise wide.
class soe::unmanaged_linux {

	require soe::repos
	include common::ipaddr::config
	include common::curl::install
	include common::hosts::default
	include common::iptables::disable
	include common::ipv6::disable
	include common::motd::default
	include common::network::service
	include common::ntp::client
	include common::puppet::client
	include common::resolv::resolvconf
	include common::selinux::disable
	include common::ssh::server
	include common::telnet::install
	include common::timezone::config
	include common::unzip::install
	include common::users::caas_root_account
	include common::vim::install
	include common::wget::install

	if $::virtual  == "vmware" {
		include common::vmwaretools::install
	}
}
