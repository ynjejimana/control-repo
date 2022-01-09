define windows::windows-firewall::fwrules ($direction, $action, $enabled, $protocol, $localport, $displayname, $description, $remoteip ) {

    windows_firewall::exception { $title :
            ensure       => present,
            direction    => $direction,
            action       => $action,
            enabled      => $enabled,
            protocol     => $protocol,
            local_port   => $localport,
            display_name => $displayname,
            description  => $description,
            remote_ip    => $remoteip
            }
}
