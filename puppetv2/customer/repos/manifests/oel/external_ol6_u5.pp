class repos::oel::external_ol6_u5 inherits repos::params {
	yum_repo { 'ol6_u5_base' :
		baseurl => 'http://public-yum.oracle.com/repo/OracleLinux/OL6/5/base/$basearch/',
	}
}
