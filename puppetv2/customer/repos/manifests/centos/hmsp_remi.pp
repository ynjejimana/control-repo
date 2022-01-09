class repos::centos::hmsp_remi ( $remi = "1" ) {
	yumrepo { 'hmsp-remi-$basearch':
	  baseurl  => 'http://repo.harbour/centos/$releasever/remi/$basearch',
	  descr    => $title,
		enabled   => $remi,
	  gpgcheck => '0',
	}
	yumrepo { 'hmsp-remi-noarch':
	  baseurl  => 'http://repo.harbour/centos/$releasever/remi/noarch',
	  descr    => $title,
	  gpgcheck => '0',
		enabled   => $remi,
	}
}
