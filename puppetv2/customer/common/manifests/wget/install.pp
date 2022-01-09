class common::wget::install {
	tag "autoupdate"

	if !defined(Package["wget"]) {
    package { "wget" :
        ensure => installed,
    }
  }
}
