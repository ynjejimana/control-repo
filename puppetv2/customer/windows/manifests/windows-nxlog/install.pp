class windows::windows-nxlog::install ( 

$nxlog_installer = undef,
$inputs          = undef,
$outputs         = undef,
$routes          = undef,
$extensions      = undef,
$savepos         = undef,
$exec            = undef,
$file            = undef,
$installnxlog    = false,
$build_dir       = 'C:\build',
$root            = 'C:\Program Files (x86)\nxlog',
$module_dir      = '%ROOT%\modules',
$cache_dir       = '%ROOT%\data',
$pid_file        = '%ROOT%\data\nxlog.pid',
$spool_dir       = '%ROOT%\data',
$log_file        = '%ROOT%\data\nxlog.log',
) {

  if $installnxlog == 'true' {
  
  $local_pkg_source = "$build_dir\\nxloginstaller.msi"

    exec { 'Create build folder':
      command => "(md $build_dir)",
      onlyif => "if ((test-path $local_pkg_source) -eq \$true) {exit 1}",
      provider => powershell,
      before => Exec['Download nxlog']
    }

    exec { 'Download nxlog':
      command => "(new-object System.Net.WebClient).DownloadFile('$nxlog_installer','$local_pkg_source')",
      onlyif => "if ((test-path $local_pkg_source) -eq \$true) {exit 1}",
      provider => powershell,
      before => Package['NXLog-CE'],
    }


    package { 'NXLog-CE':
      ensure            => installed,
      source            => $local_pkg_source,
      provider          => windows,
      install_options   => ['/quiet', '/norestart'],
      before            => File['C:\Program Files (x86)\nxlog\conf\nxlog.conf'],
    }
  
    file { 'C:\Program Files (x86)\nxlog\conf\nxlog.conf':
      ensure            => present,
      content           => template('windows/windows-nxlog/nxlog.conf.erb'),
      notify            => Service['nxlog'],
    }
  
    service { 'nxlog':
      ensure            => running,
      enable            => true,
      require           => Package['NXLog-CE'],
    }
  }

  if $installnxlog == 'remove' {

    package { 'NXLog-CE':
      ensure            => absent,
    }
  }

}
