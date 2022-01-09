class apache2::mod::php (
  $package_name   = undef,
  $package_ensure = 'present',
  $path           = undef,
  $extensions     = ['.php'],
  $content        = undef,
  $template       = 'apache2/mod/php.conf.erb',
  $source         = undef,
  $root_group     = $::apache2::params::root_group,
  $php_version    = $::apache2::params::php_version,
) inherits apache2::params {

  $mod = "php${php_version}"

  if defined(Class['::apache2::mod::prefork']) {
    Class['::apache2::mod::prefork']->File["${mod}.conf"]
  }
  elsif defined(Class['::apache2::mod::itk']) {
    Class['::apache2::mod::itk']->File["${mod}.conf"]
  }
  else {
    fail('apache2::mod::php requires apache2::mod::prefork or apache2::mod::itk; please enable mpm_module => \'prefork\' or mpm_module => \'itk\' on Class[\'apache\']')
  }
  validate_array($extensions)

  if $source and ($content or $template != 'apache2/mod/php.conf.erb') {
    warning('source and content or template parameters are provided. source parameter will be used')
  } elsif $content and $template != 'apache2/mod/php.conf.erb' {
    warning('content and template parameters are provided. content parameter will be used')
  }

  $manage_content = $source ? {
    undef   => $content ? {
      undef   => template($template),
      default => $content,
    },
    default => undef,
  }

  # Determine if we have a package
  $mod_packages = $::apache2::params::mod_packages
  if $package_name {
    $_package_name = $package_name
  } elsif has_key($mod_packages, $mod) { # 2.6 compatibility hack
    $_package_name = $mod_packages[$mod]
  } elsif has_key($mod_packages, 'phpXXX') { # 2.6 compatibility hack
    $_package_name = regsubst($mod_packages['phpXXX'], 'XXX', $php_version)
  } else {
    $_package_name = undef
  }

  $_lib = "libphp${php_version}.so"
  $_php_major = regsubst($php_version, '^(\d+)\..*$', '\1')

  ::apache2::mod { $mod:
    package        => $_package_name,
    package_ensure => $package_ensure,
    lib            => $_lib,
    id             => "php${_php_major}_module",
    path           => $path,
  }

  include ::apache2::mod::mime
  include ::apache2::mod::dir
  Class['::apache2::mod::mime'] -> Class['::apache2::mod::dir'] -> Class['::apache2::mod::php']

  # Template uses $extensions
  file { "${mod}.conf":
    ensure  => file,
    path    => "${::apache2::mod_dir}/${mod}.conf",
    owner   => 'root',
    group   => $root_group,
    mode    => $::apache2::file_mode,
    content => $manage_content,
    source  => $source,
    require => [
      Exec["mkdir ${::apache2::mod_dir}"],
    ],
    before  => File[$::apache2::mod_dir],
    notify  => Class['apache2::service'],
  }
}
