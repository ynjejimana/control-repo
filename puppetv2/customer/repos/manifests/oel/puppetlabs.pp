class repos::oel::puppetlabs inherits repos::params {
	yum_repo { 'puppetlabs-deps' :
		baseurl => "http://${repo_server}/repo/puppetlabs-deps",
	}
	yum_repo { 'puppetlabs-products' :
		baseurl => "http://${repo_server}/repo/puppetlabs-products",
	}
}
