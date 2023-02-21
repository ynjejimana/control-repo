class common::vim::install {
	if !defined(Package["vim-enhanced"]) {
    package { "vim-enhanced" :
        ensure => installed,
    }
  }
}
