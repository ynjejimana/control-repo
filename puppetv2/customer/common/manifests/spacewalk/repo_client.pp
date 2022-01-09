#
# Configuring spacewalk related repositories on the target hosts
#

class common::spacewalk::repo_client (
  $sw_version = $common::spacewalk::params::sw_version,
  $repo_server = hiera('repo_server'),
) inherits common::spacewalk::params {

  case $::operatingsystem {
    'CentOS': {
      yumrepo { 'lab-spacewalk-client':
        ensure   => present,
        baseurl  => "http://${repo_server}/repo/spacewalk-${sw_version}-client/rhel/${::operatingsystemmajrelease}/${::architecture}/",
        descr    => "Spacewalk ${sw_version} repository - Client",
        enabled  => 1,
        gpgcheck => 1,
        gpgkey   => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-spacewalk-2012',
        name     => "lab-spacewalk-${sw_version}-client",
        target   => "lab-spacewalk-${sw_version}-client.repo",
      }
      yumrepo { 'lab-epel':
        ensure   => present,
        baseurl  => "http://${repo_server}/repo/epel/${::operatingsystemmajrelease}/",
        descr    => "EPEL ${::operatingsystemmajrelease} repository",
        enabled  => 1,
        gpgcheck => 1,
        gpgkey   => "file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-${::operatingsystemmajrelease}",
        name     => "lab-epel-${::operatingsystemmajrelease}",
        target   => "lab-epel-${::operatingsystemmajrelease}",
      }
      yumrepo { 'lab-os':
        ensure   => present,
        baseurl  => "http://${repo_server}/repo/centos/${::operatingsystemrelease}/os/${::architecture}/",
        descr    => "Centos ${::operatingsystemmajrelease} OS repository",
        enabled  => 1,
        gpgcheck => 1,
        gpgkey   => "file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-${::operatingsystemmajrelease}",
        name     => "lab-centos-os-${::operatingsystemmajrelease}",
        target   => "lab-centos-os-${::operatingsystemmajrelease}",
      }

    }
    'OracleLinux': {
      yumrepo { 'lab-spacewalk-client':
        ensure   => present,
        baseurl  => "http://${repo_server}/repo/spacewalk-${sw_version}-client/rhel/${::operatingsystemmajrelease}/${::architecture}/",
        descr    => "Spacewalk ${sw_version} repository - Client",
        enabled  => 1,
        gpgcheck => 1,
        gpgkey   => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-spacewalk-2012',
        name     => "lab-spacewalk-${sw_version}-client",
        target   => "lab-spacewalk-${sw_version}-client.repo",
      }
      yumrepo { 'lab-epel':
        ensure   => present,
        baseurl  => "http://${repo_server}/repo/epel/${::operatingsystemmajrelease}/",
        descr    => "EPEL ${::operatingsystemmajrelease} repository",
        enabled  => 1,
        gpgcheck => 1,
        gpgkey   => "file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-${::operatingsystemmajrelease}",
        name     => "lab-epel-${::operatingsystemmajrelease}",
        target   => "lab-epel-${::operatingsystemmajrelease}",
      }
      yumrepo { 'lab-os':
        ensure   => present,
        baseurl  => "http://${repo_server}/repo/oel/${::operatingsystemrelease}/os/${::architecture}/",
        descr    => "OEL ${::operatingsystemmajrelease} OS repository",
        enabled  => 1,
        gpgcheck => 1,
        gpgkey   => "file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle-ol${::operatingsystemmajrelease}",
        name     => "lab-oel-os-${::operatingsystemmajrelease}",
        target   => "lab-oel-os-${::operatingsystemmajrelease}",
      }
    }
    'SuSE': {
      yumrepo { 'lab-spacewalk-client':
        ensure   => present,
        baseurl  => '',
        descr    => "Spacewalk ${sw_version} repository - Client",
        enabled  => 1,
        gpgcheck => 1,
        gpgkey   => "http://${common::spacewalk::satellite::sw_satellite_server}/pub/gpg_keys/RPM-GPG-KEY-SUSE",
        name     => "lab-spacewalk-${sw_version}-client",
        target   => "lab-spacewalk-${sw_version}-client.repo",
      }
    }

    default: {
      fail("Target OS family ${::osfamily} is not supported. Supported OSes: RHEL, CentOS, OEL, SuSE.")
    }
  }
}

