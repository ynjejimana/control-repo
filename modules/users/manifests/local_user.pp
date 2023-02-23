define users::local_user ($username = $title, $group, $fullname, $email, $ensure, $rsa_ssh_key = undef, $dss_ssh_key = undef, $uid = undef, $managehome = true ) {

	# Sets ensure variable for .ssh directory creation/deletion
	$ensure_directory = $ensure ? {
		"present" => "directory",
		"absent" => "absent",
	}

	if $ensure == "present" {
		if $dss_ssh_key != undef {
			$ssh_key_type = "ssh-dss"
			$ssh_key = $dss_ssh_key
		}
		elsif $rsa_ssh_key != undef {
			$ssh_key_type = "ssh-rsa"
			$ssh_key = $rsa_ssh_key
		}
		else {
			fail("${username} does not have either an RSA or DSS SSH key set up correctly")
		}

		file { "/home/${username}/.ssh" :
			ensure => $ensure_directory,
			owner  => $username,
			group  => $group,
			before => Ssh_Authorized_Key[$username],
		}

		ssh_authorized_key { $username:
			ensure => $ensure,
			name   => "${fullname} (${email})",
			user   => $username,
			type   => $ssh_key_type,
			key    => $ssh_key,
		}
	}

	user { $username:
		comment    => $email,
		ensure     => $ensure,
		shell      => "/bin/bash",
		gid        => $group,
		uid        => $uid,
		managehome => $managehome,
	}

}

