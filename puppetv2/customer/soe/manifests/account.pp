define soe::account ($ensure, $uid = undef, $gid = undef, $managehome = false, $password = undef, $password_max_age = -1, $groups = undef, $home = "/home/${title}", $comment = $title, $shell = '/bin/bash', $mode = "0700", $public_keys = undef) {
	$ensure_directory = $ensure ? {
		"present" => "directory",
		"absent" => "absent",
	}

	$user_before = $ensure ? {
		"present" => undef,
		"absent" => Group[$title],
	}
	if $ensure == 'absent' {
		user { $title :
			ensure	=> 'absent',
		}
	} else {
		if $managehome == true {
			file { $home :
				ensure => $ensure_directory,
				owner  => $uid,
				group  => $gid,
				mode   => $mode,
			}
		}

		$options = {
			'ensure' 	=> $ensure,
			'name'  	=> $title,
			'managehome' 	=> $managehome,
			'shell'		=> $shell,
			'comment'	=> $comment,
			'password_max_age' => $password_max_age,
		}

		if $uid != nil {
			$options_uid = merge($options, {'uid' => $uid})
		}
		else {
			$options_uid = $options
		}

		if $gid != nil {
			$options_gid = merge($options_uid, {'gid' => $gid})
		}
		else {
			$options_gid = $options_uid
		}

		if $password != nil {
			$options_pwd = merge($options_gid, {'password' => $password})
		}
		else {
			$options_pwd = $options_gid
		}

		if $groups != nil {
			$options_final = merge($options_pwd, {'groups' => $groups})
		}
		else {
			$options_final = $options_pwd
		}

		if $public_keys != undef {
			file { "${home}/.ssh" :
				ensure	=> directory,
				owner  => $uid,
				group  => $gid,
				mode   => '0700',
			}

			$defaults = {
				ensure	=> present,
				user	=> $title,
			}

			create_resources(ssh_authorized_key, $public_keys, $defaults)
		}

		$user_options = { "${title}" => $options_final, }
		create_resources('user', $user_options)

	}
}
