class virtual::groups {

  #
  # system groups
  #
  @group { 'snmptt':
    ensure => present,
    gid    => 1062
  }

  # 
  # hmsp groups
  #
  @group { 'areddel':
    ensure => present,
    gid    => 2083
  }
  @group { 'cperez':
    ensure => present,
    gid    => 5001
  }
  @group { 'dbablinyuk':
    ensure => present,
    gid    => 5002
  }
  @group { 'dgrayhurst':
    ensure => present,
    gid    => 5003
  }
  @group { 'dklenowski':
    ensure => present,
    gid    => 5004
  }
  @group { 'iahmed':
    ensure => present,
    gid    => 5005
  }
  @group { 'jwu':
    ensure => present,
    gid    => 5006
  }
  @group { 'ngorr':
    ensure => present,
    gid    => 675
  }
  @group { 'pshead':
    ensure => present,
    gid    => 2161
  }
  @group { 'slafitte':
    ensure => present,
    gid    => 683
  }
  @group { 'scrampsey':
    ensure => present,
    gid    => 5100
  }
  @group { 'mcousseau':
    ensure => present,
    gid    => 5101
  }
}
