_osfamily               = fact('osfamily')
_operatingsystem        = fact('operatingsystem')
_operatingsystemrelease = fact('operatingsystemrelease').to_f

case _osfamily
when 'RedHat'
  $confd_dir        = '/etc/httpd/conf.d'
  $conf_file        = '/etc/httpd/conf/httpd.conf'
  $ports_file       = '/etc/httpd/conf/ports.conf'
  $vhost_dir        = '/etc/httpd/conf.d'
  $vhost            = '/etc/httpd/conf.d/15-default.conf'
  $run_dir          = '/var/run/httpd'
  $service_name     = 'httpd'
  $package_name     = 'httpd'
  $error_log        = 'error_log'
  $suphp_handler    = 'php5-script'
  $suphp_configpath = 'undef'

  if (_operatingsystem == 'Fedora' and _operatingsystemrelease >= 18) or (_operatingsystem != 'Fedora' and _operatingsystemrelease >= 7)
    $apache_version = '2.4'
    $mod_dir        = '/etc/httpd/conf.modules.d'
  else
    $apache_version = '2.2'
    $mod_dir        = '/etc/httpd/conf.d'
  end
when 'Debian'
  $confd_dir        = '/etc/apache/conf.d'
  $mod_dir          = '/etc/apache/mods-available'
  $conf_file        = '/etc/apache/apache2.conf'
  $ports_file       = '/etc/apache/ports.conf'
  $vhost            = '/etc/apache/sites-available/15-default.conf'
  $vhost_dir        = '/etc/apache/sites-enabled'
  $run_dir          = '/var/run/apache2'
  $service_name     = 'apache2'
  $package_name     = 'apache2'
  $error_log        = 'error.log'
  $suphp_handler    = 'x-httpd-php'
  $suphp_configpath = '/etc/php5/apache2'

  if _operatingsystem == 'Ubuntu' and _operatingsystemrelease >= 13.10
    $apache_version = '2.4'
  elsif _operatingsystem == 'Debian' and _operatingsystemrelease >= 8.0
    $apache_version = '2.4'
  else
    $apache_version = '2.2'
  end
when 'FreeBSD'
  $confd_dir        = '/usr/local/etc/apache4/Includes'
  $mod_dir          = '/usr/local/etc/apache4/Modules'
  $conf_file        = '/usr/local/etc/apache4/httpd.conf'
  $ports_file       = '/usr/local/etc/apache4/Includes/ports.conf'
  $vhost            = '/usr/local/etc/apache4/Vhosts/15-default.conf'
  $vhost_dir        = '/usr/local/etc/apache4/Vhosts'
  $run_dir          = '/var/run/apache24'
  $service_name     = 'apache24'
  $package_name     = 'apache24'
  $error_log        = 'http-error.log'

  $apache_version = '2.2'
when 'Gentoo'
  $confd_dir        = '/etc/apache/conf.d'
  $mod_dir          = '/etc/apache/modules.d'
  $conf_file        = '/etc/apache/httpd.conf'
  $ports_file       = '/etc/apache/ports.conf'
  $vhost            = '/etc/apache/vhosts.d/15-default.conf'
  $vhost_dir        = '/etc/apache/vhosts.d'
  $run_dir          = '/var/run/apache2'
  $service_name     = 'apache2'
  $package_name     = 'www-servers/apache'
  $error_log        = 'http-error.log'

  $apache_version = '2.4'
else
  $apache_version = '0'
end

