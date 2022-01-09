class os_hardening::drivers (
    $disable_drivers = [ 'dccp' , 'cramfs' , 'sctp' , 'rds' , 'tipc' ],
){
    define disable_driver ($driver = $title) {
        file { "/etc/modprobe.d/${driver}-disable":
            ensure  => present,
            owner   => root,
            group   => root,
            mode    => '0644',
            content => "install ${driver} /bin/false",
        }
    }

    # disable drivers
    disable_driver { $disable_drivers: }
}
