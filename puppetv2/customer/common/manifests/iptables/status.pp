class common::iptables::status ( $isEnabled = false)
{
	if $isEnabled
	{
		include common::iptables::enable
	} else {
		include common::iptables::disable
	}
}
