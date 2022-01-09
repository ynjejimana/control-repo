# Pushing GPG keys to Satellite server into /var/www/html/pub
#
class common::spacewalk::gpg_keys (
  $gpg_path = '/etc/pki/rpm-gpg',
) {

  File {
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => 0644,
  }

  file { $gpg_path:
    recurse => true,
    source  => 'puppet:///modules/common/spacewalk/gpg_keys',
  }

  file { '/tmp/register_gpg.sh':
    ensure  => present,
    mode    => '0755',
    source  => 'puppet:///modules/common/spacewalk/register_gpg.sh',
    require => File[$gpg_path],
  }

  exec { 'register_rpm_gpg_keys':
    command     => "/tmp/register_gpg.sh ${gpg_path}",
    path        => [ '/bin' ],
    subscribe   => File[$gpg_path],
    refreshonly => true,
    require     => File['/tmp/register_gpg.sh'],
  }

}
