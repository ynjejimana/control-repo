class repos::centos::hmsp_percona ( $percona = "1" ) {
	yumrepo { 'hmsp-percona-$basearch':
	  baseurl  => 'http://repo.harbour/centos/$releasever/percona/$basearch',
	  descr    => $title,
		enabled   => $percona,
	  gpgcheck => '0',
	}
	yumrepo { 'hmsp-percona-noarch':
	  baseurl  => 'http://repo.harbour/centos/$releasever/percona/noarch',
	  descr    => $title,
	  gpgcheck => '0',
		enabled   => $percona,
	}
}
