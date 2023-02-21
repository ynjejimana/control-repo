node 'agent01.lab.com' {

        include apache
	include motd
        include issue
        include git
        include curl
        include wget
        include vim

}

node 'agent02.lab.com' {

        include apache
	include motd
        include issue
        include git
        include curl
        include wget
        include vim
}

node 'agent03.lab.com' {

        include apache
	include motd
        include issue
        include git
        include curl
        include wget
        include vim
}

