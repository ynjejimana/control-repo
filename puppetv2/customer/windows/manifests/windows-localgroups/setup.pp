class windows::windows-localgroups::setup (

  $managelocalgroups = 'false',
  $groups	     = [],

) {

  define local_groups (
    $group,
    $accounts,
  ) {
      exec { "Set up $group group":
        command  => "& ${systemdrive}\\windows\\System32\\net.exe localgroup \"${group}\" ${accounts} /add",
        path	 => $::path,
	provider => powershell,
	onlyif	 => "if ((Compare-Object (([ADSI]\"WinNT://./${group}\").psbase.invoke('Members') | %{\$_.gettype().invokemember('Name','getproperty',\$null,\$_,\$null)}) (@(\"${accounts}\".Split(',')) | ForEach-Object {\$_ = [regex]::Matches(\$_.Substring(\$_.IndexOfAny('\\')+1), '([^(?>=@)]+)').Groups[1].Value ; \$_ }) | ?{\$_.sideindicator -eq '=>'}) -eq \$null) { exit 1 }",
      }
  }

  if $managelocalgroups == 'true' {
    create_resources(windows::windows-localgroups::setup::local_groups, $groups)
  }

}