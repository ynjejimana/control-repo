class apache2::default_confd_files (
  $all = true,
) {
  # The rest of the conf.d/* files only get loaded if we want them
  if $all {
    case $::osfamily {
      'freebsd': {
        include ::apache2::confd::no_accf
      }
      default: {
        # do nothing
      }
    }
  }
}
