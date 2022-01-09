class repos::oel::external_ol6latest inherits repos::params {
	yum_repo { 'ol6_latest' :
		baseurl => 'http://public-yum.oracle.com/repo/OracleLinux/OL6/latest/$basearch/',
	}
}
