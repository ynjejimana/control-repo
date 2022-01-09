class common::resolv::resolvconf ($nameservers, $search_domains, $domain_name = $::domain, $options = undef) {
	class { "resolv_conf":
		nameservers => $nameservers,
		searchpath  => $search_domains,
		domainname  => $domain_name,
    options     => $options
	}
}
