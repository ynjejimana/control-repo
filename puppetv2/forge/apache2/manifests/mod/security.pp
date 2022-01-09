class apache2::mod::security (
  $crs_package                = $::apache2::params::modsec_crs_package,
  $activated_rules            = $::apache2::params::modsec_default_rules,
  $modsec_dir                 = $::apache2::params::modsec_dir,
  $modsec_secruleengine       = $::apache2::params::modsec_secruleengine,
  $audit_log_parts            = $::apache2::params::modsec_audit_log_parts,
  $secpcrematchlimit          = $::apache2::params::secpcrematchlimit,
  $secpcrematchlimitrecursion = $::apache2::params::secpcrematchlimitrecursion,
  $allowed_methods            = 'GET HEAD POST OPTIONS',
  $content_types              = 'application/x-www-form-urlencoded|multipart/form-data|text/xml|application/xml|application/x-amf',
  $restricted_extensions      = '.asa/ .asax/ .ascx/ .axd/ .backup/ .bak/ .bat/ .cdx/ .cer/ .cfg/ .cmd/ .com/ .config/ .conf/ .cs/ .csproj/ .csr/ .dat/ .db/ .dbf/ .dll/ .dos/ .htr/ .htw/ .ida/ .idc/ .idq/ .inc/ .ini/ .key/ .licx/ .lnk/ .log/ .mdb/ .old/ .pass/ .pdb/ .pol/ .printer/ .pwd/ .resources/ .resx/ .sql/ .sys/ .vb/ .vbs/ .vbproj/ .vsdisco/ .webinfo/ .xsd/ .xsx/',
  $restricted_headers         = '/Proxy-Connection/ /Lock-Token/ /Content-Range/ /Translate/ /via/ /if/',
  $secdefaultaction           = 'deny',
  $anomaly_score_blocking     = 'off',
  $inbound_anomaly_threshold  = '5',
  $outbound_anomaly_threshold = '4',
  $critical_anomaly_score     = '5',
  $error_anomaly_score        = '4',
  $warning_anomaly_score      = '3',
  $notice_anomaly_score       = '2',
) inherits ::apache2::params {
  include ::apache2

  if $::osfamily == 'FreeBSD' {
    fail('FreeBSD is not currently supported')
  }

  ::apache2::mod { 'security':
    id  => 'security2_module',
    lib => 'mod_security2.so',
  }

  ::apache2::mod { 'unique_id_module':
    id  => 'unique_id_module',
    lib => 'mod_unique_id.so',
  }

  if $crs_package  {
    package { $crs_package:
      ensure => 'installed',
      before => File[$::apache2::confd_dir],
    }
  }

  # Template uses:
  # - $modsec_dir
  # - $audit_log_parts
  # - secpcrematchlimit
  # - secpcrematchlimitrecursion
  file { 'security.conf':
    ensure  => file,
    content => template('apache2/mod/security.conf.erb'),
    mode    => $::apache2::file_mode,
    path    => "${::apache2::mod_dir}/security.conf",
    owner   => $::apache2::params::user,
    group   => $::apache2::params::group,
    require => Exec["mkdir ${::apache2::mod_dir}"],
    before  => File[$::apache2::mod_dir],
    notify  => Class['apache2::service'],
  }

  file { $modsec_dir:
    ensure  => directory,
    owner   => $::apache2::params::user,
    group   => $::apache2::params::group,
    mode    => '0555',
    purge   => true,
    force   => true,
    recurse => true,
  }

  file { "${modsec_dir}/activated_rules":
    ensure  => directory,
    owner   => $::apache2::params::user,
    group   => $::apache2::params::group,
    mode    => '0555',
    purge   => true,
    force   => true,
    recurse => true,
    notify  => Class['apache2::service'],
  }

  file { "${modsec_dir}/security_crs.conf":
    ensure  => file,
    content => template('apache2/mod/security_crs.conf.erb'),
    require => File[$modsec_dir],
    notify  => Class['apache2::service'],
  }

  apache2::security::rule_link { $activated_rules: }

}
