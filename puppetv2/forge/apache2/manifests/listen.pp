define apache2::listen {
  $listen_addr_port = $name

  # Template uses: $listen_addr_port
  concat::fragment { "Listen ${listen_addr_port}":
    target  => $::apache2::ports_file,
    content => template('apache2/listen.erb'),
  }
}
