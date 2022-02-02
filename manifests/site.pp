node puppet.lab.com {
  include role::master
}

node 'agent1.lab.com' {
  package { 'vim' :
    ensure => present,
  }
}


node 'agent2.lab.com' {
  package { 'vim' :
    ensure => present,
  }
}

node 'agent3.lab.com' {
  package { 'vim' :
    ensure => present,
  }
}

