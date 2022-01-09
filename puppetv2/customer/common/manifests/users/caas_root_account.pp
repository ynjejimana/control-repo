# Sets the root password
class common::users::caas_root_account (
        $password = $::random_password
) {
  user { "root":
    ensure   => present,
    password => generate('/bin/sh', '-c', "openssl passwd -1 ${password} | tr -d '\n'"),
  }
}
