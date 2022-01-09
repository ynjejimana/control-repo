define dhcp::pool (
    $network,
    $mask,
    $range = false,
    $gateway,
    $pxeserver = false,
    $pxefilename = "pxelinux.0",
    $allow_unknown_clients = false,
  ) {

    include dhcp::params

    $dhcp_dir = $dhcp::params::dhcp_dir

    concat_fragment { "dhcp.conf+70_${name}.dhcp":
      content => template('dhcp/dhcpd.pool.erb'),
    }

}

