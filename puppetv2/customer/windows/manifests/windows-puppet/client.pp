class windows::windows-puppet::client ($interval) {

     scheduled_task { 'Puppet NOOP run':
         ensure    => present,
         enabled   => true,
         command   => "${::env_windows_installdir}/bin/puppet.bat",
         arguments => 'agent --test --noop',
         trigger   => {
           schedule   => daily,
           start_time => '07:00',
           }
     }

     exec { 'runinterval':
         command  => "puppet.bat config set runinterval ${interval}",
         onlyif   => "if ( (puppet.bat config print runinterval) -eq ${interval} ) { exit 1 }",
         path     => "${::env_windows_installdir}/bin",
         provider => powershell,
         }

}

