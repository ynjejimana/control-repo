# == Definition: postfix::hash
#
# Creates postfix hashed "map" files. It will create "${name}", and then build
# "${name}.db" using the "postmap" command. The map file can then be referred to
# using postfix::config.
#
# === Parameters
#
# [*name*]   - the name of the map file.
# [*ensure*] - present/absent, defaults to present.
# [*source*] - file source.
#
# === Requires
#
# - Class["postfix"]
#
# === Examples
#
#   postfix::hash { '/etc/postfix/virtual':
#     ensure => present,
#   }
#   postfix::config { 'virtual_alias_maps':
#     value => 'hash:/etc/postfix/virtual',
#   }
#
define postfix::hash (
  $ensure='present',
  $source=undef,
  $content=undef,
) {
  include ::postfix::params

  validate_absolute_path($name)
  validate_string($source)
  validate_string($content)
  validate_string($ensure)
  validate_re($ensure, ['present', 'absent'],
    "\$ensure must be either 'present' or 'absent', got '${ensure}'")

  if (!defined(Class['postfix'])) {
    fail 'You must define class postfix before using postfix::config!'
  }

  if $source and $content {
    fail 'You must provide either \'source\' or \'content\', not both'
  }

  File {
    mode    => '0600',
    owner   => root,
    group   => root,
    seltype => $postfix::params::seltype,
  }

  file { $name:
    ensure  => $ensure,
    source  => $source,
    content => $content,
    require => Package['postfix'],
  }

  file {"${name}.db":
    ensure  => $ensure,
    require => [File[$name], Exec["generate ${name}.db"]],
  }

  exec {"generate ${name}.db":
    command     => "postmap ${name}",
    #creates    => "${name}.db", # this prevents postmap from being run !
    subscribe   => File[$name],
    path        => "/usr/bin:/usr/sbin:/bin:/usr/local/bin",
    refreshonly => true,
  }
}
