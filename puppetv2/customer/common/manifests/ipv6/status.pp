class common::ipv6::status ( $isEnabled = false)
{
	if $isEnabled
	{
		include common::ipv6::enable
	} else {
		include common::ipv6::disable
	}
}
