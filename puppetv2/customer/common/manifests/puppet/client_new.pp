class common::puppet::client_new (
    $puppet_server = 'puppet.esbu.lab.com.au',
    $version = '3.5.1',
    $dns_alt_names = [],
    $noclient = false,
    $update_puppet_cron = false,
    $splaylimit = '30m',
    $service_name = 'puppet',
    $service_enabled = true,
    $service_running = true,
)
{

    # Only run this code if the server is not a puppetmaster
    if !defined(Class['common::puppet::puppetmaster']) {
        class { "::puppet::client_new" :
            puppet_server    => $puppet_server,
            noclient         => $noclient,
            version          => $version,
            dns_alt_names    => $dns_alt_names,
            splaylimit       => $splaylimit,
            service_name     => $service_name,
            service_enabled  => $service_enabled,
            service_running  => $service_running,
        }

        Cron {
            month    => "*",
            monthday => "*",
            user     => "root",
            minute   => fqdn_rand( 60 ),
        }

        $ensure_update_puppet_cron = $update_puppet_cron ? {
            true  => "present",
            false => "absent",
        }

        cron { "update-puppet":
            command => "/usr/bin/puppet agent --test --tags common::puppet::client_new,common::puppet::cron --logdest syslog > /dev/null 2>&1",
            hour    => "*/2",
            ensure  => $ensure_update_puppet_cron,
        }
    }
}
