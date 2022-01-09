class common::puppet::puppetmaster (
  $foreman_server_url = 'foreman.esbu.lab.com.au',
  $servername = 'puppet.esbu.lab.com.au',
  $ca = false,
  $ca_server = 'puppetca.esbu.lab.com.au',
  $noclient = true,
  $version = installed,
  $puppet_provider = 'puppetssh',
  $hiera_repo_name = 'hiera',
  $puppet_repo_name = 'puppetv2',
  $dns_alt_names = [],
  ) {
  $puppet_prod_envs = ['production', 'dr']
  $puppet_dev_envs = ['development', 'lab']
  $puppet_envs = flatten([$puppet_prod_envs, $puppet_dev_envs])
  $puppet_production_checkout_dir = '/etc/puppet/modules/production-checkout'
  $puppet_development_checkout_dir = '/etc/puppet/modules/development-checkout'
  $hiera_production_checkout_dir = '/etc/puppet/hiera/production-checkout'
  $hiera_development_checkout_dir = '/etc/puppet/hiera/development-checkout'
  $puppet_user = 'puppet'
  $puppet_group = 'puppet'
  $git_server = hiera('git_server')

  class {'::puppet::server' :
    version             => $version,
    dns_alt_names       => $dns_alt_names,
    foreman_server_url  => $foreman_server_url,
    servername          => $servername,
    ca                  => $ca,
    ca_server           => $ca_server,
    noclient            => $noclient,
    puppet_provider     => $puppet_provider,
    puppet_environments => $puppet_envs,
  }

  class { '::git' : }

  Vcsrepo {
    owner => $puppet_user,
    group => $puppet_group,
    provider => git,
    ensure => present,
  }

  file { ['/etc/puppet/hiera', '/etc/puppet/hiera/data']:
    ensure => directory,
    owner  => $puppet_user,
    group  => $puppet_group,
    mode   => '0644',
  }

  # Puppet deals with arrays in a shit way, so we have to define a function so we can
  # do something for each item in an environment array
  # $name is the name of the Puppet environment
  define puppet_env_dir($env) {
    $puppet_production_checkout_dir = '/etc/puppet/modules/production-checkout'
    $puppet_development_checkout_dir = '/etc/puppet/modules/development-checkout'
    $hiera_production_checkout_dir = '/etc/puppet/hiera/production-checkout'
    $hiera_development_checkout_dir = '/etc/puppet/hiera/development-checkout'

    if $env == 'development' {
      $puppet_target_dir = $puppet_development_checkout_dir
      $hiera_target_dir = $hiera_development_checkout_dir
    }
    else {
      $puppet_target_dir = $puppet_production_checkout_dir
      $hiera_target_dir = $hiera_production_checkout_dir
    }

    file { "/etc/puppet/modules/${name}" :
      ensure => link,
      target => $puppet_target_dir,
    }

    file { "/etc/puppet/hiera/data/${name}" :
      ensure => link,
      target => $hiera_target_dir,
    }
  }

  puppet_env_dir { $puppet_dev_envs :
    env => 'development',
  }

  puppet_env_dir { $puppet_prod_envs :
    env => 'production',
  }

  vcsrepo { $puppet_development_checkout_dir :
    source   => "git@${git_server}:unix/${puppet_repo_name}.git",
    require  => Class['::git'],
    revision => 'development',
  }

  vcsrepo { $puppet_production_checkout_dir :
    source   => "git@${git_server}:unix/${puppet_repo_name}.git",
    require  => Class['::git'],
    revision => 'master',
  }

  vcsrepo { $hiera_development_checkout_dir :
    source   => "git@${git_server}:unix/${hiera_repo_name}.git",
    revision => 'development',
    require  => Class['::git'],
  }

  vcsrepo { $hiera_production_checkout_dir :
    source   => "git@${git_server}:unix/${hiera_repo_name}.git",
    revision => 'master',
    require  => Class['::git'],
  }

  Cron {
    month => '*',
    monthday => '*',
    user => 'root',
    minute => fqdn_rand( 60 ),
  }

  cron { 'update-puppet':
    command  => '/usr/bin/puppet agent --test --tags common::puppet::puppetmaster,common::puppet::cron --logdest syslog > /dev/null 2>&1',
  }

  if $::operatingsystem == 'RedHat' {
    file { '/etc/pki/rpm-gpg/RPM-GPG-KEY-foreman':
      ensure => file,
      owner  => root,
      group  => root,
      source => 'puppet:///modules/common/spacewalk/gpg_keys/RPM-GPG-KEY-foreman',
    }

    gpg_key { 'RPM-GPG-KEY-foreman':
      path => '/etc/pki/rpm-gpg/RPM-GPG-KEY-foreman'
    }

    Gpg_key['RPM-GPG-KEY-foreman'] -> Package <| |>
  }
}
