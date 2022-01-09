class windows::windows-symantecav::installer ( $installersource,$managementserverip,$altmanagementserverip,$sslcert,$installsymantecav )  {

$sslcertlocation = 'c:\build\symantec-agent-cert.ssl'
$installerlocation = 'C:\build\agent.exe'

if $installsymantecav == 'true' {

  file {'C:\build\agent.exe':
    ensure                       => directory,
    source                       => $installersource,
    mode                         => 0755,
  }

  file {'c:\build\symantec-agent-cert.ssl':
    content                      => $sslcert,
    ensure                       => file,
    mode                         => 0755,
    require                      => File['C:\build\agent.exe'],
  }

  package {'UniversalForwarder':
    source                       => $installerlocation,
    ensure                       => installed,
    provider                     => windows,
    require                      => File['c:\build\symantec-agent-cert.ssl'],
    install_options              => [
      '/qn',
      { '/l'                     => 'c:\build\symantecav.log' },
      { "MANAGEMENT_SERVER"      => $managementserverip },
      { "SSL_CERT_FILE"          => $sslcertlocation },
      { "ALT_MANAGEMENT_SERVER"  => $altmanagementserverip },
    ],
  }
}
}
