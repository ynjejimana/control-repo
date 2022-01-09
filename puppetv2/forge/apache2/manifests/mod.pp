define apache2::mod (
  $package        = undef,
  $package_ensure = 'present',
  $lib            = undef,
  $lib_path       = $::apache2::lib_path,
  $id             = undef,
  $path           = undef,
  $loadfile_name  = undef,
  $loadfiles      = undef,
) {
  if ! defined(Class['apache2']) {
    fail('You must include the apache base class before using any apache defined resources')
  }

  $mod = $name
  #include apache #This creates duplicate resources in rspec-puppet
  $mod_dir = $::apache2::mod_dir

  # Determine if we have special lib
  $mod_libs = $::apache2::params::mod_libs
  if $lib {
    $_lib = $lib
  } elsif has_key($mod_libs, $mod) { # 2.6 compatibility hack
    $_lib = $mod_libs[$mod]
  } else {
    $_lib = "mod_${mod}.so"
  }

  # Determine if declaration specified a path to the module
  if $path {
    $_path = $path
  } else {
    $_path = "${lib_path}/${_lib}"
  }

  if $id {
    $_id = $id
  } else {
    $_id = "${mod}_module"
  }

  if $loadfile_name {
    $_loadfile_name = $loadfile_name
  } else {
    $_loadfile_name = "${mod}.load"
  }

  # Determine if we have a package
  $mod_packages = $::apache2::params::mod_packages
  if $package {
    $_package = $package
  } elsif has_key($mod_packages, $mod) { # 2.6 compatibility hack
    $_package = $mod_packages[$mod]
  } else {
    $_package = undef
  }
  if $_package and ! defined(Package[$_package]) {
    # note: FreeBSD/ports uses apxs tool to activate modules; apxs clutters
    # httpd.conf with 'LoadModule' directives; here, by proper resource
    # ordering, we ensure that our version of httpd.conf is reverted after
    # the module gets installed.
    $package_before = $::osfamily ? {
      'freebsd' => [
        File[$_loadfile_name],
        File["${::apache2::conf_dir}/${::apache2::params::conf_file}"]
      ],
      default => [
        File[$_loadfile_name],
        File[$::apache2::confd_dir],
      ],
    }
    # if there are any packages, they should be installed before the associated conf file
    Package[$_package] -> File<| title == "${mod}.conf" |>
    # $_package may be an array
    package { $_package:
      ensure  => $package_ensure,
      require => Package['httpd'],
      before  => $package_before,
      notify  => Class['apache2::service'],
    }
  }

  file { $_loadfile_name:
    ensure  => file,
    path    => "${mod_dir}/${_loadfile_name}",
    owner   => 'root',
    group   => $::apache2::params::root_group,
    mode    => $::apache2::file_mode,
    content => template('apache2/mod/load.erb'),
    require => [
      Package['httpd'],
      Exec["mkdir ${mod_dir}"],
    ],
    before  => File[$mod_dir],
    notify  => Class['apache2::service'],
  }

  if $::osfamily == 'Debian' {
    $enable_dir = $::apache2::mod_enable_dir
    file{ "${_loadfile_name} symlink":
      ensure  => link,
      path    => "${enable_dir}/${_loadfile_name}",
      target  => "${mod_dir}/${_loadfile_name}",
      owner   => 'root',
      group   => $::apache2::params::root_group,
      mode    => $::apache2::file_mode,
      require => [
        File[$_loadfile_name],
        Exec["mkdir ${enable_dir}"],
      ],
      before  => File[$enable_dir],
      notify  => Class['apache2::service'],
    }
    # Each module may have a .conf file as well, which should be
    # defined in the class apache2::mod::module
    # Some modules do not require this file.
    if defined(File["${mod}.conf"]) {
      file{ "${mod}.conf symlink":
        ensure  => link,
        path    => "${enable_dir}/${mod}.conf",
        target  => "${mod_dir}/${mod}.conf",
        owner   => 'root',
        group   => $::apache2::params::root_group,
        mode    => $::apache2::file_mode,
        require => [
          File["${mod}.conf"],
          Exec["mkdir ${enable_dir}"],
        ],
        before  => File[$enable_dir],
        notify  => Class['apache2::service'],
      }
    }
  } elsif $::osfamily == 'Suse' {
    $enable_dir = $::apache2::mod_enable_dir
    file{ "${_loadfile_name} symlink":
      ensure  => link,
      path    => "${enable_dir}/${_loadfile_name}",
      target  => "${mod_dir}/${_loadfile_name}",
      owner   => 'root',
      group   => $::apache2::params::root_group,
      mode    => $::apache2::file_mode,
      require => [
        File[$_loadfile_name],
        Exec["mkdir ${enable_dir}"],
      ],
      before  => File[$enable_dir],
      notify  => Class['apache2::service'],
    }
    # Each module may have a .conf file as well, which should be
    # defined in the class apache2::mod::module
    # Some modules do not require this file.
    if defined(File["${mod}.conf"]) {
      file{ "${mod}.conf symlink":
        ensure  => link,
        path    => "${enable_dir}/${mod}.conf",
        target  => "${mod_dir}/${mod}.conf",
        owner   => 'root',
        group   => $::apache2::params::root_group,
        mode    => $::apache2::file_mode,
        require => [
          File["${mod}.conf"],
          Exec["mkdir ${enable_dir}"],
        ],
        before  => File[$enable_dir],
        notify  => Class['apache2::service'],
      }
    }
  }

  Apache2::Mod[$name] -> Anchor['::apache2::modules_set_up']
}
