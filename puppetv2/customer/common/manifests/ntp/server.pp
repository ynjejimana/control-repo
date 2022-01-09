# The list of servers that ntpd uses should be defined for the common::ntp::client class
# This class just modifies the client class ntp resource to enable the server component
class common::ntp::server inherits common::ntp::client {
	Class["::ntp"] {
		server_enabled => true,
	}
}
