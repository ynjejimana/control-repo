# Sets the root password
class common::users::root_account ( $password, $manage_password, $password_max_age ) {
  tag "autoupdate"

  if $manage_password == true {
    user { "root":
      ensure   => present,
      password => $password,
      password_max_age => $password_max_age,
    }
  } else {
    user { "root":
      ensure   => present,
      password_max_age => $password_max_age,
    }
  }

}

