define apache2::namevirtualhost {
  $addr_port = $name

  # Template uses: $addr_port
  concat::fragment { "NameVirtualHost ${addr_port}":
    target  => $::apache2::ports_file,
    content => template('apache2/namevirtualhost.erb'),
  }
}
