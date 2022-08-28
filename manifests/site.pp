node master.lab.com {
  include role::master
}

node 'agent.lab.com' {
  package { 'vim' :
    ensure => present,
  }
}


node 'client.lab.com' {
  package { 'vim' :
    ensure => present,
  }
}

