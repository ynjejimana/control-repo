class windows::windows-networking::dnsclients (
  $enablednsclients = hiera('windows::windows-networking::dnsclients::enablednsclients',true)
) {

  unless $enablednsclients == false {

    $windowsdnsservers = hiera('windows::windows-networking::dnsclients::windowsdnsservers',undef)
    $expecteddnsservers = regsubst($windowsdnsservers, '\'', '', 'G')

    if $::domainrole == 'Standalone Server' or $::domainrole == 'Member Server' {

      if $::virtual == 'hyperv' {
        exec { 'windows-dns' :
          command   => "(Set-DnsClientServerAddress -InterfaceIndex $(Get-NetAdapter | Where-object {$_.Name -like "*Ethernet*" } | Select-Object -ExpandProperty InterfaceIndex) -ServerAddresses (${windowsdnsservers}))",
          onlyif    => "if ( \"${::dnsservers}\" -eq \"${expecteddnsservers}\" ) {exit 1}",
          provider  => powershell,
          logoutput => true
        }
      } else {
        exec { 'windows-dns' :
          command   => "(get-wmiobject -class win32_networkadapterconfiguration | where { \$_.defaultipgateway -ne \$null}).setdnsserversearchorder(@(${windowsdnsservers}))",
          onlyif    => "if ( \"${::dnsservers}\" -eq \"${expecteddnsservers}\" ) {exit 1}",
          provider  => powershell,
          logoutput => true
        }
      }

    }

  }

}
