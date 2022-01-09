#DO NOT USE this REPO unless specified too
#Required by Confluence wiki server

class repos::centos::mysql_community {

  if $::operatingsystem == 'CentOS' {
    yum_repo { 'mysql-community' :
      baseurl => "http://repo.mysql.com/yum/mysql-5.6-community/el/6/\$basearch",
      enabled => $enabled,
      gpgcheck => '0',
    }
  }
}
