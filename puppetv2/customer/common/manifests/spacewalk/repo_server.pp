#
# Configuring spacewalk related repositories on the target hosts
#
class common::spacewalk::repo_server (
  $sw_version = $common::spacewalk::params::sw_version,
  $repo_server = hiera('repo_server'),
) inherits common::spacewalk::params {

  case $::osfamily {
    'RedHat': {
      yumrepo { 'spacewalk-server':
        ensure   => present,
        baseurl  => "http://${repo_server}/repo/spacewalk/${sw_version}/RHEL/${::operatingsystemmajrelease}/${::architecture}/",
        descr    => "Spacewalk ${sw_version} repository - Server",
        enabled  => 1,
        gpgcheck => 0,
#       gpgkey   => 'http://yum.spacewalkproject.org/RPM-GPG-KEY-spacewalk-2012',
        name     => 'spacewalk-server',
        target   => 'spacewalk-server.repo',
      }
      if $sw_version > 2.6 {

      yumrepo { 'spacewalk-java-packages':
          ensure   => present,
          baseurl  => "http://${repo_server}/repo/spacewalk-java-packages/",
          descr    => 'spacewalk server java',
          enabled  => 1,
          gpgcheck => 0,
          name     => 'spacewalk-server-java',
          target   => 'spacewalk-server-java.repo',
      }
    }

      if $sw_version <= 2.6 {
        yumrepo { 'jpackage-generic':
          ensure   => present,
          baseurl  => "http://${repo_server}/repo/jpackage-generic/",
  #       mirrorlist => 'http://www.jpackage.org/mirrorlist.php?dist=generic&type=free&release=5.0',
          descr    => 'JPackage generic',
          enabled  => 1,
          gpgcheck => 0,
  #       gpgkey     => 'http://www.jpackage.org/jpackage.asc',
          name     => 'jpackage-generic',
          target   => 'jpackage-generic.repo',
        }
    }
}
    default: {
      fail("Target OS family ${::osfamily} is not supported. Use RedHat, CentOS or OEL.")
    }
  }
}
