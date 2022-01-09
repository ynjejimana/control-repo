class nfs::nfs3_mount_point ($nfs_server, $nfs_server_directory, $mount_directory) {

	file { $mount_directory:
		ensure => directory,
	}

	mount { $mount_directory :
		ensure   => mounted,
		remounts => true,
		fstype   => "nfs",
		options  => "rw,bg,intr,hard,timeo=600,wsize=32768,rsize=32768,nfsvers=3,tcp",
		device   => "${nfs_server}:${nfs_server_directory}",
	}

}
