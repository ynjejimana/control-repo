class accounts {

  user { njejimyv:
    ensure      => present,
    home        => '/home/njejimyv',
    shell       => '/bin/bash',
    managehome  => true,
    uid         => '1001',
    password    => '98efdd090e868e55c76761aaec6cea54'
  }

}
