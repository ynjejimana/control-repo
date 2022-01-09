class repos::centos::hmsp_fusionio ( $fusionio = "1" ) {
	yumrepo { 'hmsp-fusionio-$basearch':
	  baseurl  => 'http://repo.harbour/centos/$releasever/fusionio/$basearch',
	  descr    => $title,
		enabled   => $fusionio,
	  gpgcheck => '0',
	}
	yumrepo { 'hmsp-fusionio-noarch':
	  baseurl  => 'http://repo.harbour/centos/$releasever/fusionio/noarch',
	  descr    => $title,
	  gpgcheck => '0',
		enabled   => $fusionio,
	}
}
