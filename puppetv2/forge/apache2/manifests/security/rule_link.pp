define apache2::security::rule_link () {

  $parts = split($title, '/')
  $filename = $parts[-1]

  file { $filename:
    ensure  => 'link',
    path    => "${::apache2::mod::security::modsec_dir}/activated_rules/${filename}",
    target  => "${::apache2::params::modsec_crs_path}/${title}",
    require => File["${::apache2::mod::security::modsec_dir}/activated_rules"],
    notify  => Class['apache2::service'],
  }
}
