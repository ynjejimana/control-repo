class virtual::nrlabusers {

  @user { 'oracle':
    name       => "oracle",
    ensure     => present,
    uid        => 54321,
    gid        => 54321,
    home       => '/home/oracle',
    managehome => true
  }

  @ssh_authorized_key {"chen@cap":
    ensure => present,
    name   => 'chen@cap',
    user   => 'oracle',
    type   => 'ssh-rsa',
    key    => "AAAAB3NzaC1yc2EAAAABJQAAAQEA2pqZVzB6vmyzBcRfKrbfVuLOLwfzEBnUMmd9/3JF9IrH/kj/PalmHFsYS9kIkWlcZV0gxdkFR+O93g+QjEmfYGlcyHKBENjwl/A2/29J1uYgoEXga7PtMYgS5dx/imQgds6NMHIwzI3DzU0g2K9fz1YxsYYGXvdwj4tj97dki/N9W7MKa2RdBHQ/xHm3bsWBzueEd6vdCiLVHV9dsL/XPlH22GiKFadlwcli0Q766OjxXPSw+OS2hGvwhC0GObJgd7ussyGQYXet9xpyfhXUfb4S0t1OLpIcLDziFRCrjnyCldUfZ3yjOzTLGZbnElO1H6IaKpdIORLG1jBaXvu8IQ=="
  }

   @ssh_authorized_key { "patil@cap":
    ensure => present,
    name   => 'patil@cap',
    user   => 'oracle',
    type   => 'ssh-rsa',
	  key     => "AAAAB3NzaC1yc2EAAAABJQAAAQBtR160MklYU/J8As5KM2LgethgW5c2yV6ISuGHWAyp0wVPIa5JALdQ+pufPS3GJ6k+U6eCoUobGgp5zIkEeIp5dvGoEARM1n4jihY79dDURRvUobX3SbbHt2tfE5/0+tBxfKD0r0F0UP/uXNkEPCqIv+qOrz15tDrjKsWGwGRqjRqfb+ClLbHv+sbPt+z+Q40tPIcmQ7bj91Z3C+DOJHWkny5UkhJ6N/xVV0PJ+TWL7/q4bUJ7HqL5sJV2NdXLCvIhHuPwjkNvG+5FdaT2sz9eLKWljgVzAsPnjA2V1F6zx9nxEKEXcowTto1/95FEjTQ9XaqgmYADeEvTCdq/3++b"
  }

 @ssh_authorized_key { "asif@cap":
    ensure => present,
    name   => 'asif@cap',
    user   => 'oracle',
    type   => 'ssh-rsa',
		key      => "AAAAB3NzaC1yc2EAAAABJQAAAQEAga0/6nwai+kvSWvuNkPsE0oobuxjrCod2nLiYWql2k80aPsUYGDvWg7341S++yKdVVDega92uW7A8yAnyyWOMkzJUa9WG79ZgcdIxwxAScFkHMsl4hqYlU2IAC7rtBmFP1O1whoEewvA3lUjHSz2rlgtPpplGbR1fZoPceXFctkUAnW0AaTj2wr7aLly944d3tBBFJ2YofZmN82l4f0F4MvRjTYHxAmH9/VM4LLR/DDR+5IjmJow6zfzQEqoG4oX3F7gwWmzDIVK7jYASxzuKKDA6lDi3LDMpeT9Ia1ilVbgBdqMHY0040B9LSomK41rA+9wFpRhq1iE9l69jYPhQw=="
  }
}
