class windows::windows-domainjoin::join ($domain, $domainjoinaccount, $domainjoinpassword, $machine_ou) {

   # Join options - https://msdn.microsoft.com/en-us/library/aa392154(v=vs.85).aspx

$domainjoin = hiera('windows::windows-domainjoin::join::domainjoin','False')

   if $::domainrole == "Standalone Server" and $domainjoin == "True" {

       class { 'domain_membership':
           domain      => $domain,
           username    => $domainjoinaccount,
           password    => $domainjoinpassword,
           machine_ou  => $machine_ou,
      	   join_options => '3',
           require     => Class['windows::windows-networking::dnsclients'],
           }
   }
}
