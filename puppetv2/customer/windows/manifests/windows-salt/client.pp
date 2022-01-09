class windows::windows-salt::client ( $master, $saltminion_installer ) {

        #Install Salt Minion
        package { 'Salt Minion 2015.5.5' :
             ensure          =>  installed,
             source          =>  $saltminion_installer,
             provider        =>  windows,
             install_options =>  ['/S',"/master=${master}","/minion-name=${::fqdn}"],
             before          =>  Service['salt-minion'],
             }

        service { 'salt-minion' :
             ensure            =>  running,
             }
}
