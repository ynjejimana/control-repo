# Installs curl
class common::curl::install {
	tag "autoupdate"

	if !defined(Package["curl"]) {
		package { "curl" :
			ensure => installed,
		}
	}
}
