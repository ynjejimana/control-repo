# == Define: sssd::domain
# This type is used to define one or more domains which SSSD
# will authenticate against.
#
define sssd::domain (
  $ldap_domain = $name,
  $ldap_filter = undef,
) {
  include sssd::params

  concat::fragment { "sssd_domain_${ldap_domain}":
    target  => 'sssd_conf',
    content => template('sssd/domain.conf.erb'),
    order   => 20,
  }
}
