class repos::centos::hmsp_vmware ( $vmware = "1" ) {
	yumrepo { 'hmsp-vmware-$basearch':
	  baseurl  => 'http://repo.harbour/centos/$releasever/vmware/$basearch',
	  descr    => $title,
		enabled   => $vmware,
	  gpgcheck => '0',
	}
	yumrepo { 'hmsp-vmware-noarch':
	  baseurl  => 'http://repo.harbour/centos/$releasever/vmware/noarch',
	  descr    => $title,
	  gpgcheck => '0',
		enabled   => $vmware,
	}
}
