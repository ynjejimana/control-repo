class ntta::portal::mysql ($root_dbpassword, $bind_address = hiera('ntta::portal::mysql::bind_address','127.0.0.1')) {

class { 'mysql::server':
      config_hash => { 'root_password'      => $root_dbpassword ,
      'bind_address'  => $bind_address, },
    }

}
