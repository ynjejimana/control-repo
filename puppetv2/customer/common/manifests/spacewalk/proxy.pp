# Installing SpaceWalk proxy server 
#
class common::spacewalk::proxy (

  $sw_satellite_server = pick(hiera(common::spacewalk::sw_satellite_server),$common::spacewalk::params::sw_satellite_server),
  $sw_version = $common::spacewalk::params::sw_version,


  $sw_admin_email = pick(hiera(common::spacewalk::sw_admin_email),$common::spacewalk::params::sw_admin_email),
  $sw_ca_org = pick(hiera(common::spacewalk::sw_ca_org),$common::spacewalk::params::sw_ca_org),
  $sw_ca_org_unit = pick(hiera(common::spacewalk::sw_ca_org_unit),$common::spacewalk::params::sw_ca_org_unit),
  $sw_ca_city = pick(hiera(common::spacewalk::sw_ca_city),$common::spacewalk::params::sw_ca_city),
  $sw_ca_state = pick(hiera(common::spacewalk::sw_ca_state),$common::spacewalk::params::sw_ca_state),
  $sw_ca_country_code = pick(hiera(common::spacewalk::sw_ca_country_code),$common::spacewalk::params::sw_ca_country_code),
  $sw_ca_cert_email = pick(hiera(common::spacewalk::sw_ca_cert_email),$common::spacewalk::params::sw_ca_cert_email),
  $sw_ca_cert_password = pick(hiera(common::spacewalk::sw_ca_cert_password),$common::spacewalk::params::sw_ca_cert_password),
  $sw_sat_pass = pick(hiera(common::spacewalk::sw_ca_cert_password),$common::spacewalk::params::sw_ca_cert_password),

) inherits common::spacewalk::params {

  include common::spacewalk::repo_server
  include common::spacewalk::client

  $pkgProxyList = ['spacewalk-proxy-selinux','spacewalk-proxy-installer']

  package {$pkgProxyList:
    ensure  => installed,
    require => Yumrepo['spacewalk-server'],
  }


  file {'/root/ssl-build':
    ensure => directory,
    owner  => root,
    group  => root,
  }

  file {'/var/spool/squid':
    ensure => directory,
  }


  file {'/tmp/sat_proxy_answer':
    ensure  => present,
    owner   => root,
    group   => root,
    replace => true,
    content => template('common/spacewalk/spacewalk.proxy.answer.erb'),
  }

  #exec {'configure-proxy':
  # command => '/bin/ls',
  # cwd     => '/tmp',
  # unless  => '',
  #}


}

