class windows::windows-puppetagentpremissions::setup ( 
  $adminmanaged	= 'false',
) {

  if $adminmanaged == 'true' {

    $ssl = regsubst($puppet_vardir,'.{3}$','')
    exec { 'Set owner for puppet/var':
      command	=> "cmd.exe /c icacls ${puppet_vardir} /setowner BUILTIN\\Administrators /T",
      path	=> $::path,
      unless	=> "cmd.exe /c \"dir ${puppet_vardir} /q | findstr BUILTIN\\Administrators\"",
    }

    exec { 'Set owner for puppet/etc/ssl':
      command	=> "cmd.exe /c icacls ${ssl}/etc/ssl /setowner BUILTIN\\Administrators /T",
      path	=> $::path,
      unless	=> "cmd.exe /c \"dir ${ssl}/etc/ssl /q | findstr BUILTIN\\Administrators\"",
    }

  }
}