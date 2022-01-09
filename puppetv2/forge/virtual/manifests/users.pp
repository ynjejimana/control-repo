class virtual::users {

 group { 'hmspadmins':
   ensure     => present
 }

  #
  # system users
  #

  @user { 'snmptt':
    ensure     => present,
    name       => "snmptt",
    uid        => 1062,
    gid        => 1062,
    home       => '/home/snmptt',
    managehome => false
  }
  
  # 
  # hmsp users
  #

  @user { 'areddel':
    ensure     => present,
    uid        => 2075,
    gid        => 2083,
    home       => '/home/areddel',
    managehome => true,
  }

  @ssh_authorized_key { "areddel":
    ensure => present,
    name   => 'areddel@harbourmsp.com',
    user   => 'areddel',
    type   => 'ssh-dss',
    key    => "AAAAB3NzaC1kc3MAAACBAPZTO6LXWhbVl2y4xY58kOyBnUB7OKK3USNpP5vr3YIKBGAE9LgR3BUsbPb/pNwotfuQF6j9DrOwvVPE+CTBgD/mTwZXQJ/ZzlZ0RE6JjBNOr6InHMXQxF7jKU0OVpw47OpyWBVdPO71znYskNAHQHESwg5bOMJiRJIleaREsOudAAAAFQCg4nYSZqlIiW4iudrZraNm5BgGKQAAAIBUmBa1IUWU+eTsjGlxYPEl7a65eH+PEwiuZ9Ft6XyKQ6NNB6s21Wq5Cv3rDiEJPgMKjjGZh0mF30DT2Un54+ACJT1/GOZuHy2tj7+E7lzFgKc0C6Bh3esw02cwRyTVCSVDSiNWivb0c9Ds8SG1eOXTFbZp4E3900Fna9SPbiTeWAAAAIEAxoDTr0B+5Ar+tDHih5N0LfAhduEbQiV0KdpRebgeTzgBHf8XAQZzzoUA9AHjo3GsN58joDzN/D2msfECGq3k/noFCfXzR3gUgkCNj4PzDpttqmFkKBYo3HMTdyPz4b/GFNpZpL/J4DAIpPkqBx+Fe3ce8T6Fg6p0Bs/ZPuMFG5A="
  }


  @user { 'cperez':
    ensure     => present,
    uid        => 5001,
    gid        => 5001,
    home       => '/home/cperez',
    managehome => true
  }

  @ssh_authorized_key { "cperez":
    ensure => present,
    name   => 'cperez@harbourmsp.com',
    user   => 'cperez',
    type   => 'ssh-dss',
    key    => "AAAAB3NzaC1kc3MAAACBALT4tDTqs9H/afLK+anlnhAFa0TmoXnIs7I9jRWXgCcwZMUOn+IeqSK7jh829R0icKLTupMpL+J4ide9fHb4rEWh5Q4L9apbOgkjOsXF2fVdRFFc6y+TTymHCeRlaSB/SHYEMNKSi0x6un/dPiYfux9/TkNk0sqVhjgyRGZ+akIjAAAAFQCncbS/pBeEgdeM1gJbcZ1N3FkqGwAAAIBxxfWq5h9nLTyErdW7fPJpIXu4zL4S1HpDZZOCn08CZ1MMBCbtp7ZtEJqtT2rUfN9Fx937mwBt1R9Zv5HadKa9hJJS3tRlkMRNQIFDSlcd517Gmz839+tHMaMbJURs3an//VoUPDtB+W8X1qiQIgZGChfTlVKrOsPVtYSlCjSK8QAAAIB6Pz7QVow3QWXVM4o8J1KaX5xxBw86ENqwGLEvmzdJVJMuZGcfHIVZ8l/CqvX+o1a/aKGUz4R/grkdeJ2voGlol4eFOGUUOkuA0ffvF3Wy8bxAhuElGbQidAoR9lzItWB92m0xRPoJ3MAFe5dGoMr897bKTHphTlW9YbDB8nX0ag=="
  }


  @user { 'dbablinyuk':
    ensure     => present,
    uid        => 5002,
    gid        => 5002,
    home       => '/home/dbablinyuk',
    managehome => true,
		groups       => 'hmspadmins'
  }

  @ssh_authorized_key { "dbablinyuk":
    ensure => present,
    name   => 'dbablinyuk@harbourmsp.com',
    user   => 'dbablinyuk',
    type   => 'ssh-dss',
key       => "AAAAB3NzaC1kc3MAAACBAO1B+fxS1L6oCetvbuC0OutxOuFtNaQXDnl+6cNp/5nzWd4h5P2Hb2wHi536I93uaUIFltRTje4YhGgQJwAywHMLfc9cgBkmfrN84WsQnBnu7ot0uzRREbaVlIm4ePufSrFWOMmJi+lIigPM6vTOHJAXi8/DV+13wBEQRng2bUktAAAAFQDy2EY3zoUj+Bv7y6JxXOmSR+SDiQAAAIA1UrAplebFN+H9en3kOvYn0gDQjs3FUG+q/gVM0Hpska8ZdGlM8TpT/gdsEkBbOdRZp0hzQxJo1f39GCfhAVw+ROK4dk9Mc9wb7IxSyxTpMv3aVQkLfnHXyxtP55a8Nzxy76yazybPAbn3FWo53mkUrrSb1aptBn89z9yUZJOLLgAAAIEAtJ9sGXjIC/m1AgYiOWDm5qH0ADYX9Loh9jahZd/apEPW4aJO9g5s8zO13s0VqzBSeK9PE3EyX8H9oCpPu5eVmzxAmWkLooV3IfUOYh/thchvWq/Frad8B4+t8B//nkUulXov/y4p/6Uvs9NpqI2LENn9v/wm1uIabamjtgb9hrI="
  }


  @user { 'dgrayhurst':
    ensure     => present,
    uid        => 5003,
    gid        => 5003,
    home       => '/home/dgrayhurst',
    managehome => true,
		groups       => 'hmspadmins'
  }

   @ssh_authorized_key {
	  "dgrayhurst":
    	require => User["dgrayhurst"],
			ensure => present,
	    name => 'dgrayhurst@harbourmsp.com',
	    user => 'dgrayhurst',
	    type => 'ssh-rsa',
	    key => "AAAAB3NzaC1yc2EAAAADAQABAAABAQDFGuOs479jGenCFISPUGC9ry2Vf8jCYsrdPkWsEUM4E7woahv4kzCdOQntN3YnN4RW9LmAW2nDa+NGn8tcc8kCsgYUpimS7Xzk+Zq2Tjbx3x6+r2Aq+bvIaPZRrPjkZAhpPb0mBnMVVaKRAundSOTscrQFtEfU9YtKD+wlP9b5ZzndGH2wfqLvuYBSsNyzTnTQ5o7/B0tzqIcuXRtG+j/Gfvi1A+8I56l25TdkgH7ThYegrldD4mCC5sUuAlUAL45Nn/pOyqRu3Sr/+hqGQBfCXv8V6syC6j/PcZkcvbnTcuzBLfLYmQ0WNizujH/RGQcjB+y4TYfXvMBHz1uv+ORZ";
	  "dgrayhurst-oracle":
    	ensure => present,
	    name => 'oracle-dgrayhurst@harbourmsp.com',
	    user => 'oracle',
	    type => 'ssh-rsa',
	    key => "AAAAB3NzaC1yc2EAAAADAQABAAABAQDFGuOs479jGenCFISPUGC9ry2Vf8jCYsrdPkWsEUM4E7woahv4kzCdOQntN3YnN4RW9LmAW2nDa+NGn8tcc8kCsgYUpimS7Xzk+Zq2Tjbx3x6+r2Aq+bvIaPZRrPjkZAhpPb0mBnMVVaKRAundSOTscrQFtEfU9YtKD+wlP9b5ZzndGH2wfqLvuYBSsNyzTnTQ5o7/B0tzqIcuXRtG+j/Gfvi1A+8I56l25TdkgH7ThYegrldD4mCC5sUuAlUAL45Nn/pOyqRu3Sr/+hqGQBfCXv8V6syC6j/PcZkcvbnTcuzBLfLYmQ0WNizujH/RGQcjB+y4TYfXvMBHz1uv+ORZ";

	}

  @user { 'iahmed':
    ensure     => present,
    uid        => 5005,
    gid        => 5005,
    home       => '/home/iahmed',
    managehome => true,
		groups       => 'hmspadmins'
  }

  @ssh_authorized_key { "iahmed":
    ensure => present,
    name   => 'iahmed@harbourmsp.com',
    user   => 'iahmed',
    type   => 'ssh-dss',
    key    => "AAAAB3NzaC1kc3MAAACBAOa/I9kdf20BJGZZ70/ZYIzX1iutUjQ3cPWB+6vWIDSEBZZzdU4u6EOU67pshVFUeAkuIzRvjWcLVnlAlXmwTNwLrzGxumTGDYA0n82YHnoDHnR8X9ugb/DPqA6xp0PZGLUEcVx6uAgdw4h0yWK9DMgwbP2C6Min/otP3O209UI/AAAAFQC4KNClP4hMcCtUvrUz2nH8vbav9wAAAIBQlEOlwAtNqOIPNzJvBxEMaUHepscWOyXOquhFvhtABoGEtYDzLcho82nqRB4L/yTfkKK69ZoS3XdtkzVzpG5vJvK67p3Cebx3NxCLXueQ+khlp+oIkqjDfmhylN5oOp1ZvFjR3NQmo+9Z0kevNv79SY+l7F4VzzpR8PZpSvJWigAAAIBTw77z6MAh2/GDColO8L9o6GemEYAaQLyg7yMk9E6VqOKLUH6SQC9U389uPutBSM3L0VSdQN3lXOJjH4J2NsVcmdMxEQN9PZh59Hu+WbxM3xQ+BrNFsvXagOKGd2iACGPGR1eeAvZh/LPz8oDx4Dlq/M02elmSHVE9BYshQoBJIQ=="
  }


  @user { 'jwu':
    ensure     => present,
    uid        => 5006,
    gid        => 5006,
    home       => '/home/jwu',
    managehome => true,
		groups       => 'hmspadmins'
  }

  @ssh_authorized_key { "jwu":
    ensure => present,
    name   => 'jwu@harbourmsp.com',
    user   => 'jwu',
    type   => 'ssh-dss',
    key    => "AAAAB3NzaC1kc3MAAACBAJeyK2otnq69Lpw/lqNHuKijaZ/hibpWxd9I2Bmrk83ImvEynB0iTaK/+oX7lNUuAiiEt+gK4+zE+7x8S0VGwNvBOD5bw9gdLVb4aI/iNci3nMz/rhFRoXIK6iO9Lh7UzpOAEC1Ehe2PqxPGi/Eir0+nDXYWhB7o36SIIu4XY/HPAAAAFQChHTu5vdiU0Y4Lnesjw19elxebkwAAAIBuQ8sOykEUl6m3rxpvgRhy9Gn/Qy+k4jCEbsJEo0TfsPcWKzH6xHxMc08XlEICbsON6kO2bZE7MME+k88cWU/g+6RmBufHvDn1INMllPSgHSjnJYZGH++NddWnENPkeMkIlszfTfLNmQOm+I8tt+cJYfyLdQzD+7kTktTDJdGABQAAAIBF6ZzGS4qRWQrGT3sFPZql7i13qdvFq3rwRi4lHPCcD/69OENVjnag3Imolw+ztuBcZrvJVD+9brDmKput0o1kp2h+/3txjAw6sebwd0tvMXZHK5tyOKYqcC2ZJlhXJKRUqC7D193CqDCSf6LmQl3g771sE9WJIXCP6ob8qwVW6Q=="
  }


  @user { 'ngorr':
    ensure     => present,
    uid        => 675,
    gid        => 675,
    home       => '/home/ngorr',
    managehome => true,
		groups       => 'hmspadmins'
  }

  @ssh_authorized_key { "ngorr":
    ensure => present,
    name   => 'ngorr@harbourmsp.com',
    user   => 'ngorr',
    type   => 'ssh-rsa',
    key    => "AAAAB3NzaC1yc2EAAAADAQABAAABAQDAjQ8vRo3onX7sqpBAVwJNZNqgYdRuuG4bte0qACTF0bocoY1NvdQHnsd4WXFamiaSMvRrz4I51h3N5Dhh7/l23FOmnybdGxtOeXOdUfF3YVO7fu0rg1D8EPSEZL3V/jl6jiqq92WbQj2JRVvoXWTpYpOXAoNhErrjoUIKsrE8hWHuwpzTEbMwb/F/UHwMjYKiNp9LOEoDoXAAGO2ys//5KoS570u+PdMHIPDsyCQW7q8RvZ9caYUR34mTa0bhD4ZYNep9Ducqmop8V50RRnjOT5sqCvHJsc3lO7NazIP1kNdieBCH5Q5AS+ygVzcOQ7yizjBBG3r+hBdMvuQZulaD"
  }


  @user { 'pshead':
    ensure     => present,
    uid        => 2137,
    gid        => 2161,
    home       => '/home/pshead',
    managehome => true,
		groups       => 'hmspadmins'
  }

  @ssh_authorized_key { "pshead":
    ensure => present,
    name   => 'pshead@harbourmsp.com',
    user   => 'pshead',
    type   => 'ssh-dss',
    key    => "AAAAB3NzaC1kc3MAAACBANvHCU6Mfm1GpJeQYxnd5ctOe1JsTJt7qxB7OlnlUZ1aitEKIRh8xdcnY1kvJsGkGX5v2WvxtjnauoaaWOWQP38AZQlhWIhhgf6QSIKv12Eqg71hX2mxh+3H+U8UG1dAtqz42LuYHUD4H3j7MJqyoM/A+w6d9/5G/sz/OPfR6JJNAAAAFQDs268u86UzkK41xAUQgOd7QHWY6wAAAIEAq9Rdq7psTIImixcpxn0M/UwlmTmaReG2At+iM7E0+xiR8Rb/Dg5S7BGuAGQK255t880kce1x7m1sYETlSXz6jPTcVJMTbl0KWq3Ye85IaodFmuwAVyuHQ7vjGAXve0TTBV7nBoZmKtc6+9wyzJo7/bd8T6mAZI4BAgq+RyoaGhcAAACAY2VjnkHx8c3D3OlS94ggvDGeqsnTsfLIr8REZzoi5c1q9E7ZSzEosmLIc5pb+TiS5rf/9sUjoD3duq4FQpWYgVVmRuLozuw1MjZFKbcWaTaEx+ix70odrPmphnoNdgcw6WF8jERth1VlXAaimk9AqUQJI9rZ8S+FTJXXna3/R0U="
  }


  @user { 'slafitte':
    ensure     => present,
    uid        => 683,
    gid        => 683,
    home       => '/home/slafitte',
    managehome => true,
		groups       => 'hmspadmins'
  }

  @ssh_authorized_key { "slafitte":
    ensure => present,
    name   => 'slafitte@harbourmsp.com',
    user   => 'slafitte',
    type   => 'ssh-dss',
    key    => "AAAAB3NzaC1kc3MAAACBAPAt9MGSaVTpvAJQd5eITei2cHD8GWjXcXKZ9qfxh0S3hH5eWiFYQ3bo+H9PcRWkjstbHXZIucqIXtKGRQR7debjV1jjfjKW6IA5d43KokyNdxSkeTiT8fulRkP6FLpLNth3BmJq+gWKGxtzz0Osqh6nXVfp9NUi+YIOm1i15sCXAAAAFQDSHssfqohycY4+0sKKWC/ep3r+bwAAAIEAuwgolkDdVE6sWoV8zlG0K4vSSEl6l/sQ81E4GA3C+11QJxGb/pErGmLz5iRdVk0VuPdQDHtevUA4Qgnt+FprfoInvdSX/EOLlM4iYhydsSwfsWkE+SEHLHXIIAliydw4ZXBoIZd92IOmlxsRXYZHELG+q4702M3hPHAmMbgWMosAAACAEV2B2zfLRUPlrCJb4ZhnZVaRwP2zxqyAkIhCkSyqnw1Jr5SdjTyqfbZ2/8vM400PmLYeWUuHnkXLQhUbNZtAneXNn+6YiNaAo5jIgdBgAz1b8tOoMy+jMDJTd4HdSuxlEleeeouG4xEQKRVJY3uFRqEeDXup2IDHl9WJ7EQlFCY="
  }

  @user { 'scrampsey':
    ensure     => present,
    uid        => 5100,
    gid        => 5100,
    home       => '/home/scrampsey',
    managehome => true,
		groups       => 'hmspadmins'
  }

  @ssh_authorized_key { "scrampsey":
    ensure => present,
    name   => 'scrampsey@harbourmsp.com',
    user   => 'scrampsey',
    type   => 'ssh-rsa',
    key    => "AAAAB3NzaC1yc2EAAAADAQABAAABAQDZW6nA5qJO2KJqh7NpeoYKLnr2cRs2lrvg0R/GKWYR+fzjBSMGkEYSniaO9DyS4NZfILlqm7yI4IjLZLMEkfnYWx+Is8Q0pbVr3o5qRuusSXcgaj6zQhsZxBrehQbJQQ7Nou63mXOkL6m2s+jh2PWlScOX3tQNFW2rrjdEOinDLlrzSmpbdns3Og9YowjmLCrMS7Kz4mFrzYnbJ89HKHTll90u/nE7qw5TR6wy0Xu6pwqXbY8lPzh3hdl1KZHpzfcH8RdhDuQ6Wdxlfs1Ri3MEStaLA+RxPTyWdWfgfklhJjBaz6B99fYPMWW+UO1h/0dqFfVXNIep6u8bWbV7l6B9"
  }

# max
  @user { 'mcousseau':
    ensure     => present,
    uid        => 5101,
    gid        => 5101,
    home       => '/home/mcousseau',
    managehome => true,
		groups       => 'hmspadmins'
  }
  
  @ssh_authorized_key { "mcousseau":
    ensure => present,
    name   => 'mcousseau@harbourmsp.com',
    user   => 'mcousseau',
    type   => 'ssh-rsa',
    key    => "AAAAB3NzaC1yc2EAAAADAQABAAABAQDPN7Zn7zJ3kVnF0ZjkOJE3GXTcHCTAhO5KGOA6f0q49sG2wOvBFHr5ca/hjnlxDJBaNkmlLeUraWJaaDcsiTtYHPxAOzeQqkwPCKh6rHHKIJIfk4gMjtivGtDpDwUwXG8Z3W4etPFm+LVLb/qf0vWlROcSyy/hMzzOrUu3A4cyilXUnOfrcpQU4o1slv9CTgyTkEgqVDzTPEB0pZXC9yoRC+vN49iODOSDZ7qwzDQHgW5aZUOSBJtJ+bB3bI+l7gVSxB0ZOBO0Uj4r/7b1lXAQ5VFOgOs69JL6s8M4DrHsnuBjpTHRMAQlb9NALAUUebJI/zgv3mWwO2fRiaRBdaS9"
  }

}
