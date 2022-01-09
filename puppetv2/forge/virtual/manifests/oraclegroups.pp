class virtual::oraclegroups {

  # 
  # oracle groups
  #
  @group { 'flexclone':
    ensure => present,
    gid    => 54324
  }
  
  @group { 'oinstall':
    ensure => present,
    gid    => 501
  }
  
}
