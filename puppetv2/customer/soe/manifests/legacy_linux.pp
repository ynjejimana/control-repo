# Legacy SOE linux class that includes the bare minimum required classes.
# This class deliberately omits the repo and local user classes. 
# Do not modify this class without extensively
# testing the additions as it is deployed enterprise wide.
class soe::legacy_linux {


	include soe::stages
	include common::audit::audit
	include common::curl::install
	include common::hosts::default
	include common::iptables::disable
	include common::ipv6::disable
	include common::motd::default
	include common::network::service
	include common::ntp::client
	include common::puppet::client
	include common::puppet::cron
	include common::resolv::resolvconf
	include common::selinux::disable
	include common::ssh::server
	include common::telnet::install
	include common::timezone::config
	include common::unzip::install
	include common::users::root_account
	include common::vim::install
	include common::wget::install


	#include common::users::admin_group
	#include common::users::recovery_account
	#include common::users::unix_accounts

	#include repos::centos::centos
	#include repos::centos::centos_misc
	#include repos::centos::epel
	#include repos::centos::foreman
	#include repos::centos::foreman_plugins
	#include repos::centos::scl


	if $::virtual  == "vmware" {
		include common::vmwaretools::install
	}
}
