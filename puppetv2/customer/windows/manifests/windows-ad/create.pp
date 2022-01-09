class windows::windows-ad::create ( $domainname,$netbiosdomainname,$localadminpassword,$dsrmpassword,$dns )  {

  if $::domainrole == 'Standalone Server' {

    class { 'windows_ad':

      install                => present,
      installmanagementtools => true,
      restart                => true,
      installflag            => true,
      configure              => present,
      configureflag          => true,
      domain                 => 'forest',
      domainname             => $domainname,
      netbiosdomainname      => $netbiosdomainname,
      domainlevel            => '6',
      forestlevel            => '6',
      databasepath           => 'c:\\windows\\ntds',
      logpath                => 'c:\\windows\\ntds',
      sysvolpath             => 'c:\\windows\\sysvol',
      installtype            => 'domain',
      dsrmpassword           => $dsrmpassword,
      installdns             => $dns,
      localadminpassword     => $localadminpassword,
      }
  }
}

