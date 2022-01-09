define repos::server::yum_repo ($baseurl = '', $mirrorlist = '', $arch = "x86_64", $destination_folder, $sync_hour = 1, $sync_minute = 0, $latest_only = true, $sha_type = "sha256") {
	$basedir = "/var/www/html/repo${destination_folder}"

	concat::fragment { "repo-${name}":
		target  => "/etc/yum_reposync.conf",
		content => template("repos/server/yum_conf.repo.erb"),
	}

	$latest_only_string = $latest_only ? {
		true => "-n",
		false => "",
	}

	cron { "sync-${name}-repo":
		command  => "mkdir -p ${basedir} && /usr/bin/reposync -q -a ${arch} -c /etc/yum_reposync.conf -r ${name} ${latest_only_string} -d -p ${basedir}; /usr/bin/createrepo -q -s ${sha_type} --simple-md-filenames --basedir=${basedir} .; chown -R apache: ${basedir}",
		user     => "root",
		month    => "*",
		monthday => "*",
		hour     => $sync_hour,
		minute   => $sync_minute,
		require  => [Package["yum-utils"], Package["createrepo"], Concat["/etc/yum_reposync.conf"]],
	}
}
