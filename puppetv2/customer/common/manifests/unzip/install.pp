class common::unzip::install {
	tag "autoupdate"
	
	if !defined(Package["wget"]) {
		package { "unzip":
			ensure => installed,
		}
	}
}
