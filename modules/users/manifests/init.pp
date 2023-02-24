class users {
  user { duser1:
    ensure	=> present,
    uid		=> '5001',
    shell	=> '/bin/bash',
    home	=> "/home/duser1",
    managehome	=> true,
    password	=> '286755fad04869ca523320acce0dc6a4'
  }

  user { duser2:
    ensure	=> present,
    uid		=> '5002',
    shell	=> '/bin/bash',
    home	=> "/home/duser2",
    managehome	=> true,
    password	=> '286755fad04869ca523320acce0dc6a4'
  }
}
