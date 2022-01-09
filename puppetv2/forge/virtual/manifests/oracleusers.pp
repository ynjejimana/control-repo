class virtual::oracleusers {

  @user { 'flexclone':
    ensure     => present,
    name       => "flexclone",
    uid        => 54323,
    gid        => 54324,
    home       => '/home/flexclone',
    managehome => false
  }

  @user { 'oracle':
    name       => "oracle",
    ensure     => present,
    uid        => 54321,
    gid        => 501,
    home       => '/home/oracle',
    managehome => false
  }
    
  @user { 'ororacrs':
    name       => "ororacrs",
    ensure     => present,
    comment    => "rac oracrs-user",
    uid        => 1003,
    gid        => 501,
    home       => '/oracrs/oracle',
    managehome => false
  }

}

