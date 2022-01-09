# Installing PostgreSQL DB on the server
#
class common::spacewalk::db (
  $sw_satellite_server = $common::spacewalk::params::sw_satellite_server,
  $sw_db_server = $common::spacewalk::params::sw_db_server,
  $sw_pg_user = $common::spacewalk::params::sw_pg_user,
  $sw_pg_group = $common::spacewalk::params::sw_pg_group,
  $sw_pg_pass = $common::spacewalk::params::sw_pg_pass,
  $sw_db_name = $common::spacewalk::params::sw_db_name,
  $sw_db_user = $common::spacewalk::params::sw_db_user,
  $sw_db_pass = $common::spacewalk::params::sw_db_pass,
  $db_dump_dir = '/var/lib/pgsql/backups',
) inherits common::spacewalk::params {

  $sw_db_host_check = pick($common::spacewalk::db::is_sw_db_check_ok,true)

  if $sw_db_host_check {

    class { '::postgresql':
      #     version             => 9.2,
      #     manage_package_repo => true,
      user  => $sw_pg_user,
      group => $sw_pg_group,
      #     service_name        => 'postgresql
      #     bindir              => '/usr/bin',
      #     datadir             => '/var/lib/pgsql/data',
      #     confdir             => '/var/lib/pgsql/data',

    } ->
    class { '::postgresql::server':
      config_hash => {
      'ip_mask_allow_all_users' => '0.0.0.0/0',
      'listen_addresses'        => '*',
      'postgres_password'       => $sw_pg_pass,
      },
    }

    class { '::postgresql::contrib': }

    class { '::postgresql::client': }


# Create the SpaceWalk DB
# Requires: spacewalk repository, spacewalk-setup-postgres package and exec for the script

    include common::spacewalk::repo_server

    package { 'spacewalk-setup-postgresql':
      ensure => installed,
      before => Exec['spacewalk-setup-postgresql'],
    }

    exec { 'spacewalk-setup-postgresql':
      command => "/usr/bin/spacewalk-setup-postgresql create --db ${sw_db_name} --user ${sw_db_user} --password ${sw_db_pass} --standalone  --address * --remote 0.0.0.0/0",
      path    => '/usr/bin:/usr/sbin:/bin:/sbin',
      cwd     => '/tmp',
      unless  => 'grep spacewalk-setup-postgresql /var/lib/pgsql/data/postgresql.conf 1>/dev/null 2>/dev/null'
    }


#  DB backup section
#  Includes scripts, cron schedules
#
    file { '/usr/local/scripts':
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }

    file { '/usr/local/scripts/db_backup.sh':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      source  => 'puppet:///modules/common/spacewalk/db_backup.sh',
      mode    => '0700',
      require => File['/usr/local/scripts'],
    }

    cron { 'db_backup':
      command => "/usr/local/scripts/db_backup.sh ${sw_pg_user} ${db_dump_dir}",
      user    => root,
      minute  => '0',
      hour    => '21',
      weekday => '6',
      name    => 'db_backup',
    }



#  Monitoring ???

  } else {
  notify { "The platform you are trying to install a SpaceWalk DB server doesn't comply the prerequisites. ${::operatingsystem}": }
  }

}

