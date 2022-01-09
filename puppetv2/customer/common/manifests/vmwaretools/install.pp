class common::vmwaretools::install (
	$download_location,
	$archive_md5 = "9df56c317ecf466f954d91f6c5ce8a6f",
	$version = "9.0.0-782409",
) {
	tag "autoupdate"

	if $::virtual == "vmware" {
		if $::osfamily == "RedHat" and ($::operatingsystemmajrelease == 7 or $::operatingsystemmajrelease == 6) and $::operatingsystem != "Fedora" {
			package { "open-vm-tools":
				ensure => installed,
			}
			service { "vmtoolsd":
				enable	=> true,
				ensure	=> running,
				require	=> Package["open-vm-tools"],
			}
		}
		else
		{
			class { "vmwaretools":
				archive_url	=> $download_location,
				archive_md5	=> $archive_md5,
				version     => $version,
			}
		}
	}
}
