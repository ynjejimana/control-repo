class windows::windows-vdbench::install ( $source,$javasource ) {

$installjava = hiera('windows::windows-vdbench::install::installjava','true')

  if $installjava == 'true' {

    exec { 'InstallJRE':
      path        =>  'C:\windows\system32',
      command     =>  "${javasource} /s", 
      onlyif      =>  'if ((Get-WmiObject -Class Win32_Product -ComputerName . -Filter "Name like \'Java%\'") -ne \$null) { exit 1 }',
      provider    =>  powershell,
      logoutput   =>  on_failure, 
      }

  }

  file { 'C:\Program Files (x86)\vdbench' :
	  path                =>  'C:\Program Files (x86)\vdbench',
		ensure              =>  directory,
		source              =>  $source,
		source_permissions  =>  ignore,
		recurse             =>  remote,
    }

}
