# Installing SpaceWalk satellite server 
#
class common::spacewalk::satellite (
  $sw_satellite_server = $common::spacewalk::params::sw_satellite_server,
  $sw_db_server = $common::spacewalk::params::sw_db_server,

  $sw_sat_user = $common::spacewalk::params::sw_sat_user,
  $sw_sat_pass = $common::spacewalk::params::sw_sat_pass,

  $sw_pg_user = $common::spacewalk::params::sw_db_osuser,
  $sw_pg_group = $common::spacewalk::params::sw_db_osgroup,
  $sw_pg_pass = $common::spacewalk::params::sw_db_pass,
  $sw_db_name = $common::spacewalk::params::sw_db_name,
  $sw_db_user = $common::spacewalk::params::sw_db_user,
  $sw_db_pass = $common::spacewalk::params::sw_db_pass,

  $uln_user = $common::spacewalk::params::uln_user,
  $uln_pass = $common::spacewalk::params::uln_pass,

  $sw_env_phases = $common::spacewalk::params::sw_env_phases,

  $sw_admin_email = $common::spacewalk::params::sw_admin_email,
  $sw_ca_org = $common::spacewalk::params::sw_ca_org,
  $sw_ca_org_unit = $common::spacewalk::params::sw_ca_org_unit,
  $sw_ca_city = $common::spacewalk::params::sw_ca_city,
  $sw_ca_state = $common::spacewalk::params::sw_ca_state,
  $sw_ca_country_code = $common::spacewalk::params::sw_ca_country_code,
  $sw_ca_cert_email = $common::spacewalk::params::sw_ca_cert_email,
  $sw_ca_cert_password = $common::spacewalk::params::sw_ca_cert_password,
  $sw_configure_apache_ssl = $common::spacewalk::params::sw_configure_apache_ssl,
  $sw_enable_cobbler = $common::spacewalk::params::sw_enable_cobbler,
  $sw_enable_pam_auth = $common::spacewalk::params::sw_enable_pam_auth,

) inherits common::spacewalk::params {

  $spacewalk_version = hiera('common::spacewalk::repo_server::sw_version',undef)
  $sw_sat_host_check = pick($common::spacewalk::satellite::is_sw_sat_check_ok,true)

  if $sw_sat_host_check {
    include common::spacewalk::repo_server
    include ::postgresql::client

    $pkglist = ['spacewalk-postgresql','spacewalk-utils']

    file { '/tmp/spacewalk.answer':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      replace => false,
      content => template('common/spacewalk/spacewalk.sat.answer.erb'),
      require => Package[$pkglist],
    }

    package {$pkglist:
      ensure  => installed,
      require => Yumrepo['spacewalk-server'],
    }

    if $spacewalk_version >= '2.5' {
    $disconnected = undef } else {
    $disconnected = '--disconnected' }

    exec { 'spacewalk-setup':
      command => "/usr/bin/spacewalk-setup ${disconnected} --external-postgresql --non-interactive --answer-file=/tmp/spacewalk.answer",
      cwd     => '/tmp',
      unless  => "/bin/grep -q ${sw_satellite_server} /etc/rhn/rhn.conf",
      require => File['/tmp/spacewalk.answer'],
      notify  => Exec['enable_pam_auth'],
    }
 



    include common::spacewalk::gpg_keys

    file { '/etc/pam.d/rhn-satellite':
      ensure => present,
      owner  => 'root',
      group  => 'root',
      source => 'puppet:///modules/common/spacewalk/rhn-satellite.pam',
      mode   => '0644',
    }

    exec { 'enable_pam_auth':
      refreshonly => true,
      command     =>  '/usr/bin/echo "pam_auth_service = rhn-satellite" >> /etc/rhn/rhn.conf',
      cwd         => '/etc/rhn',
      unless      => '/bin/grep -q pam_auth_service /etc/rhn/rhn.conf',
      require     => File['/etc/pam.d/rhn-satellite'],
      notify      => Service['tomcat'],
    }

    service { 'tomcat':
      ensure     => 'running',
      hasrestart => true,
      require    => Exec['enable_pam_auth'],
    }

    file { '/usr/local/scripts':
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
    }

    file { '/usr/local/scripts/create_repos.pl':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      source  => 'puppet:///modules/common/spacewalk/create_repos.pl',
      mode    => '0700',
      require => File['/usr/local/scripts'],
    }

    file { '/usr/local/scripts/create_channels.pl':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      source  => 'puppet:///modules/common/spacewalk/create_channels.pl',
      mode    => '0700',
      require => File['/usr/local/scripts'],
    }

    file { '/usr/local/scripts/create_keys.pl':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      source  => 'puppet:///modules/common/spacewalk/create_keys.pl',
      mode    => '0700',
      require => File['/usr/local/scripts'],
    }

    file { '/usr/local/scripts/create_orgs.pl':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      source  => 'puppet:///modules/common/spacewalk/create_orgs.pl',
      mode    => '0700',
      require => File['/usr/local/scripts'],
    }

    file { '/usr/local/scripts/repos.cfg':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      source  => 'puppet:///modules/common/spacewalk/repos.cfg',
      mode    => '0644',
      require => File['/usr/local/scripts/create_repos.pl'],
    }


    file { '/usr/local/scripts/channels.cfg':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      source  => 'puppet:///modules/common/spacewalk/channels.cfg',
      mode    => '0644',
      require => File['/usr/local/scripts/create_channels.pl'],
    }


    file { '/usr/local/scripts/keys.cfg':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      source  => 'puppet:///modules/common/spacewalk/keys.cfg',
      mode    => '0644',
      require => File['/usr/local/scripts/create_keys.pl'],
    }

    file { '/usr/local/scripts/orgs.cfg':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      source  => 'puppet:///modules/common/spacewalk/orgs.cfg',
      mode    => '0644',
      require => File['/usr/local/scripts/create_orgs.pl'],
    }


    file { '/usr/local/scripts/activate_env.pl':
      ensure => present,
      owner  => 'root',
      group  => 'root',
      source => 'puppet:///modules/common/spacewalk/activate_env.pl',
      mode   => '0755',
    }

    file { '/usr/local/scripts/manage_env.sh':
      ensure => present,
      owner  => 'root',
      group  => 'root',
      source => 'puppet:///modules/common/spacewalk/manage_env.sh',
      mode   => '0755',
    }

    file { '/usr/local/scripts/update_groups.pl':
      ensure => present,
      owner  => 'root',
      group  => 'root',
      source => 'puppet:///modules/common/spacewalk/update_groups.pl',
      mode   => '0755',
    }

    file { '/usr/local/scripts/errata_import.pl':
      ensure => present,
      owner  => 'root',
      group  => 'root',
      source => 'puppet:///modules/common/spacewalk/errata_import.pl',
      mode   => '0755',
    }

    file { '/usr/local/scripts/centos_errata_import.sh':
      ensure => present,
      owner  => 'root',
      group  => 'root',
      source => 'puppet:///modules/common/spacewalk/centos_errata_import.sh',
      mode   => '0755',
    }


$uln_conf = "[main]
username = ${uln_user}
password = ${uln_pass}"

    file { '/etc/rhn/spacewalk-repo-sync/uln.conf':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => $uln_conf,
      }

    #cron { 'latest2dev':
    #  command  => "/usr/local/scripts/manage_env.sh ${sw_satellite_server} ${sw_sat_user} ${sw_sat_pass} latest2dev",
    #  user     => root,
    #  minute   => '0',
    #  hour     => '0',
    #  monthday => '1',
    #  month    => [1, 4, 7, 10],
    #  name     => 'latest2dev',
    #}

    #cron { 'dev2qa':
    #  command  => "/usr/local/scripts/manage_env.sh ${sw_satellite_server} ${sw_sat_user} ${sw_sat_pass} dev2test",
    #  user     => root,
    #  minute   => '0',
    #  hour     => '0',
    #  monthday => '1',
    #  month    => [2, 5, 8, 11],
    #  name     => 'dev2test',
    #}

    #cron { 'qa2prod':
    #  command  => "/usr/local/scripts/manage_env.sh ${sw_satellite_server} ${sw_sat_user} ${sw_sat_pass} test2prod",
    #  user     => root,
    #  minute   => '0',
    #  hour     => '0',
    #  monthday => '1',
    #  month    => [3, 6, 9, 12],
    #  name     => 'test2prod',
    #}

    #cron { 'update_groups':
    #  command => "/usr/local/scripts/update_groups.pl ${sw_sat_user} ${sw_sat_pass}",
    #  user    => root,
    #  minute  => '0',
    #  hour    => '23',
    #  name    => 'update_groups',
    #}

    #   cron { 'errata_import':
    # command  => "/usr/local/scripts/centos_errata_import.sh ${sw_sat_user} ${sw_sat_pass}",
    # user     => root,
    # minute   => '0',
    # hour     => '22',
    # name     => 'errata_import',
    #}


  }
}
