#!/usr/bin/perl

#use strict;
#use warnings;

use Config::Simple;
use Data::Dumper;
use Net::Ping;
use Net::DNS;
use IO::Socket::INET;

require 'testingdefs.pl';
#my %conf = do 'testingdefs.pl';
#chdir $conf{path};


my $configfile = shift @ARGV;

if (!$configfile)
{
	die "Usage : $0 [config file]\n";
}
else
{
	if (! -f $configfile)
	{
		print "$0 Can not open $configfile\n";
		die "Usage : $0 [config file]\n";
	}
}

chop ($timestamp = `date "+%Y%m%d"`);
$hostfile = "/etc/hosts";

# main
initconfvars($configfile);

my ($config) = $configfile =~ /(\S+)\..*/;
$logfile = "serverbuild-$config-$timestamp";
unlink $logfile if (-f $logfile);

#checksmtp();
#checkinterfaces();
#getipaddresses();
#reportipaddresses();
#getusers();
#getldapusers();
#checkusers("passwd");
#checkusers("ldap");
#getgroups();
#getldapgroups();
#checkgroups("passwd");
#checkgroups("ldap");
#exit 0;

getserverdetails();

getipaddresses();

getpackages();

getkernelparams();

getmounts();

getopenports();

getusers();
getldapusers();
getgroups();
getldapgroups();

reportheader();

checkinterfaces();

reportipaddresses();

checkhostentries();

checkmounts();

checkperms();

#checkusers();
checkusers("passwd");

#checkgroups();
checkgroups("passwd");

standardpingchecks();

checkdns();

checkntp();

checkldap();

checksmtp();

checkpackages();

checkkernelparams();

checkopenports();

dumpkernelparams();
dumppackages();

print STDOUT "$0: output written to : $logfile\n";

exit 0;

sub initconfvars
{
	my ($configfile) = @_;

    chop ($hostname = `hostname`);
    chop ($domainname = `hostname -d`);
    chop ($fqdn = "$hostname.$domainname");
    if ($domainname eq "")
    {
        $domainname = "UNDEFINED";
    }

	print "configfile : $configfile\n";
	my $cfg = new Config::Simple("$configfile");

    %checkints = %{$cfg->get_block('interfaces')}; 

	#print Dumper \%checkints;

	#@baseints = $cfg->param('interfaces.base');
	#@bonds = $cfg->param('interfaces.bonds');
	#@vlans = $cfg->param('interfaces.vlans');
	#@bridges = $cfg->param('interfaces.bridges');


	@requiredhosts = $cfg->param('hosts.hostentries');


#print "hostname : $hostname\n";
#print "domainname : $domainname\n";
#exit 0;

    if ($hostname ne "")
    {
        unshift @requiredhosts,$hostname;
    }

    if ($domainname ne "")
    {
        unshift @requiredhosts,$fqdn;
    }

	@standardpings = $cfg->param('pings.standardpings');

	@dnsservers = $cfg->param('dns.servers');
	@dnscheckaddress = $cfg->param('dns.checkaddress');


	@mailservers = $cfg->param('mail.servers');
	$mailfrom = $cfg->param('mail.mailfrom');
	$rcptto = $cfg->param('mail.mailfrom');

	@ldapservers = $cfg->param('ldap.servers');
	$ldapsecret = $cfg->param('ldap.secret');
	$ldapdn = $cfg->param('ldap.dn');
	$ldaptestuid = $cfg->param('ldap.testuid');

	$ldapuserbase = $cfg->param('ldap.userbase');
	$ldapgroupbase = $cfg->param('ldap.groupbase');

	@checkldapusers = $cfg->param('ldap.users');

	@checkldapgroups = $cfg->param('ldap.groups');

	%perms = %{$cfg->get_block('perms')}; 

	@checkmountsnfs = $cfg->param('mounts.nfs');
	@checkmountslocal = $cfg->param('mounts.local');

	@ntpservers = $cfg->param('ntp.servers');
	@checkpkgs = $cfg->param('packages.pkgs');
	@checkkernelparams = $cfg->param('kernel.checkparams');

    @checkportprotocols = $cfg->param('ports.protocols');

    %checkusers = %{$cfg->get_block('users')}; 
    %checkgroups = %{$cfg->get_block('groups')};
}



sub getkernelparams
{
	my $sysctlcmd = "sysctl -a";

	open(CMD, "$sysctlcmd 2>&1 |") || die "Can not run cmd  '$sysctlcmd' : $!\n";
	while(<CMD>)
	{
		#my ($pkg,$ver,$release,$arch) = /^([a-zA-Z\-0-9]+)\-(\d.+)/;
		my ($param,$val) = split(/ = /,$_);

		if ($param !~ '^error')
        {
            if ($param)
            {
                #print $_;
                $kernelparams{$param} = $val;
            }
        }
	}
}

sub getpackages
{
	#my $pkgcmd = "dpkg --list | awk '{ print $2 " " $3 }'";
	#my $pkgcmd = "rpm -qa";
	my $pkgcmd = "rpm -qa --qf \"%{n} %{v} %{r} %{arch}\n\"";

	open(CMD, "$pkgcmd |") || die "Can not run cmd  '$pkgcmd' : $!\n";
	while(<CMD>)
	{
		#print $_;
		#my ($pkg,$ver,$release,$arch) = /^([a-zA-Z\-0-9]+)\-(\d.+)/;
		my ($pkg,$version,$release,$arch) = split(/ /,$_);

		#print "pkg : $pkg\n";;
		#print "ver : $version\n";;
		#print "release : $release\n";;
		#print "arch : $arch\n";;
		if ($pkg)
		{
			#$packages{$pkg} = 1;
			$packages{$pkg}{name} = $pkg;
			$packages{$pkg}{version} = $version;
			$packages{$pkg}{release} = $release;
			$packages{$pkg}{arch} = $arch;
		}
	}
}

sub getserverdetails
{
    chop ($os = `uname -o`);
    chop ($kernel = `uname -r`);
    chop ($processor = `uname -p`);

    #chop ($memtotal = `cat /proc/meminfo | grep -i MemTotal | awk '{print \$2}'`);
    #$memtotal = sprintf("%.0f", $memtotal/1024);
    chop ($memtotal = `cat /proc/meminfo | grep -i MemTotal | awk '{print \$2}'`);
    $memtotal = sprintf("%.0f", $memtotal/(1024*1024));

    chop (my $swapline = `cat /proc/swaps | grep -v "Size" | awk '{ print \$1 " " \$3 }'`);
	($swapfile,$swap) = split(' ', $swapline);

    $swap = sprintf("%.0f", $swap/(1024));

    my $distrofile;
    if (-f "/etc/enterprise-release")
    {
        $distrofile = "/etc/enterprise-release";
        chop ($distro = `cat $distrofile`);
    }
    elsif (-f "/etc/lsb-release")
    {
        $distrofile = "/etc/lsb-release";
        chop ($distro = `tail -1 $distrofile |sed -e s/DISTRIB_DESCRIPTION=//`);
	$redhatdiriv = 0;
    }
    elsif (-f "/etc/redhat-release")
    {
        $distrofile = "/etc/redhat-release";
        chop ($distro = `cat $distrofile`);
    }
    else
    {
        $distro = "UNKNOWN";
	$redhatdiriv = 0;
    }

    my $cpucmd = 'cat /proc/cpuinfo | grep name | sed -e s/"^model name.*: "// | tr -s " "';
    open(C,"$cpucmd |") || die "could not run cmd ($cpucmd) : $!\n";
    @cpus = <C>;
    close C;
}

sub getipaddresses
{
    my $ipaddresscmd = "/sbin/ifconfig -a | grep -e \"inet addr\" -e \"Link encap\" | awk  '{print \$1 \" \" \$2 \" \" \$3 \" \" \$4 }'";

    open(I,"$ipaddresscmd |") || die "could not run cmd ($ipaddresscmd) : $!\n";
    my $line = <I>;
    chop $line;
#print "line : $line\n";


    my ($interface, $address, $bcast, $mask);

    ($interface) = $line =~ /^(\S+)\s+.*/;
#print "interface : $interface\n";

    while(<I>)
    {
        my $newline = $_;
#print "newline : $newline\n";

        if ($newline =~ /inet addr/)
        {
            if ($interface ne "lo")
            {
                    ($address,$bcast,$mask) = $newline =~ /^inet addr:(\S+) Bcast:(\S+) Mask:(\S+)/;

                #print STDOUT "address : $address\n";
                #print STDOUT "bcast : $bcast\n";
                #print STDOUT "mask : $mask\n";
            }
            else
            {
                #print STDOUT "here : $newline\n";
                ($address,$mask) = $newline =~ /^inet addr:(\S+) Mask:(\S+)/;
                $bcast = "";
                #print STDOUT "address : $address\n";
                #print STDOUT "bcast : $bcast\n";
                #print STDOUT "mask : $mask\n";
            }
            push @ipaddresses,"$interface#$address#$bcast#$mask";
        }
        else
        {
            #($interface) = $newline =~ /^([a-z0-9:]+)\s+.*/;
            ($interface) = $newline =~ /^(\S+)\s+.*/;
            #print STDOUT "interface $interface\n";
        }
    }
    close I;
    chop ($defaultgw = `netstat -rn | grep "^0.0.0.0" | awk '{ print \$2}'`);
}

sub getmounts
{
	my $mountcmd = "mount | awk '{ print \$5 \"#\" \$3 \"#\" \$1 }'";
	open (M, "$mountcmd |") || die "can not run mount command : $!\n";
	while(<M>)
	{
		chop;
		push @mounts,$_;
	}
	close M;
}

sub getopenports
{

	my $openportscmd = "netstat -an | grep -i listen | grep -v unix | awk '{ print \$1 \" \" \$4 }' | sed -e 's/[0-9]*\$/ \&/' -e 's/: / /'";
	open (M, "$openportscmd |") || die "can not run mount command : $!\n";
	while(<M>)
	{
		chop;
		push @openports,join('-',$_);
	}
	close M;
}

sub getusers
{

        my $getuserscm = "cat /etc/passwd";

        open (U, "$getuserscm |") || die "can not run $getuserscm command : $!\n";
        while(<U>)
        {
            chop;
            my ($user,$p,$uid,$group,$comment,$home,$shell) = split(/:/,$_);
            $users{$user} = join(':',$uid,$group,$home,$shell);
            #print "\@users:$user : $users{$user}\n";
        }
        close M;
}

sub getldapusers
{

        my $getuserscmd = "getent passwd | grep ':*:'";

        open (U, "$getuserscmd |") || die "can not run $getuserscm command : $!\n";
        while(<U>)
        {
            chop;
            my ($user,$p,$uid,$group,$comment,$home,$shell) = split(/:/,$_);
            $ldapusers{$user} = join(':',$uid,$group,$home,$shell);
            #print "\@users:$user : $users{$user}\n";
        }
        close M;
}


sub getgroups
{

        my $getgroupscmd = "cat /etc/group";

        open (G, "$getgroupscmd |") || die "can not run $getgroupscmd command : $!\n";
        while(<G>)
        {
            chop;
            my ($group,$p,$gid,@users) = split(/:/,$_);
            $groups{$group} = join(':',$gid,@users);
            #print "\@groups:$group : $groups{$group}\n";
        }
}

sub getldapgroups
{

        my $getgroupscmd = "getent group | grep ':*:'";

        open (G, "$getgroupscmd |") || die "can not run $getgroupscmd command : $!\n";
        while(<G>)
        {
            chop;
            my ($group,$p,$gid,@users) = split(/:/,$_);
            $ldapgroups{$group} = join(':',$gid,@users);
            #print "\@groups:$group : $groups{$group}\n";
        }
}

sub checkmounts
{
	header("MOUNTS");

    my ($mount, $status, $dev, $type);

	my @nfsmounts = grep(/^nfs/,@mounts);
	my @localmounts = grep(!/^nfs/,@mounts);

	open (LOGM,">>$logfile") || die "can not open logfile($logfile) :$!\n";

	format LOGM =
    @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<    @<<<<<<<<  @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<    @<<<<<<<
    $mount,                                  $status,  $dev,          $type
.

	print LOGM "  LOCAL\n";

    $mount = "MOUNT";
    $status = "STATUS";
    $dev = "DEVICE";
    $type = "TYPE";
    write LOGM;

	foreach my $chkmnt (@checkmountslocal)
	{

		#print "local chkmnt : $chkmnt\n";
		my @found = grep(/#$chkmnt#/, @localmounts);
		if (@found)
		{
			($type,$mount,$dev) = split(/#/,$found[0]);
			$status = "FOUND";
		}
		else
		{
			$status = "NOT FOUND";
			$mount = $chkmnt;
			$type = "";
			$dev = "";
		}
        write LOGM;
	}

	print LOGM "\n  NFS\n";

    $mount = "MOUNT";
    $status = "STATUS";
    $dev = "DEVICE";
    $type = "TYPE";
    write LOGM;

	foreach my $chkmnt (@checkmountsnfs)
	{
		#print "nfs chkmnt : $chkmnt\n";
		my @found = grep(/#$chkmnt#/, @nfsmounts);
		if (@found)
		{
            #print "found\n";
			($type,$mount,$dev) = split(/#/,$found[0]);
			$status = "FOUND";
		}
		else
		{
			$status = "NOT FOUND";
			$mount = $chkmnt;
			$type = "";
			$dev = "";
            #print "not found ->$found\n";
		}
        write LOGM;
	}
	print LOGM "\n";

	close LOGM;
}

sub checkdns
{
    header("DNS");

    my $server;
    my $address;
    my $ip;
    my $status;

    checkservice("DNS",@dnsservers);

    $server = "DNS SERVER";
    $address = "ADDRESS";
    $ip = "IP ADDRESS";
    $status = "STATUS";

	open (LOGCD,">>$logfile") || die "can not open logfile($logfile) :$!\n";

	format LOGCD =
    @<<<<<<<<<<<<<<<<<<<<<<<<<<    @<<<<<<<<<<<<<<<<<<<<<<<<<<    @<<<<<<<<<<<<<<<   @<<<<<<<<<<<<<<<<<
    $server,             $address,                  ,$ip,    $status
.

    write LOGCD;

	foreach $dnsserver (@dnsservers)
    {
        my ($peerproto, $peerport);
        ($server, $ip, $peerproto, $peerport) = split(/:/,$dnsserver);

        my $res = Net::DNS::Resolver->new( nameservers => [$ip], recurse => 1, debug => 0, retry => 1, retrans => 3);

        foreach $address (@dnscheckaddress)
        {

            #print "server : $server, address : $address\n";
            my $query = $res->search($address);

            #$res->print;

            if ($query)
            {
                #print "query : $query\n";

                foreach my $rr ($query->answer)
                {
                  #print $rr->answer, "\n";
                  #print $rr->address, "\n";
                    $status = $rr->address;
                    write LOGCD;
                }
            }
            else
            {
                  #$status = "$res->errorstring";
                  $status = "NOT FOUND ($res->errorstring)";
            write LOGCD;
            }
        }
	}
    print LOGCD "\n";

    close LOGCD;
}

sub checksocket
{
    my ($servicename, $peeraddress, $peerproto, $peerport) = @_;

    my $service = "SERVICE";
    my $address = "ADDRESS";
    my $proto = "PROTOCOL";
    my $port = "PORT";
    my $status = "STATUS";

    open (LOGCS,">>$logfile") || die "can not open logfile($logfile) :$!\n";

    format LOGCS =
    @<<<<<<<<    @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<     @<<<<<    @<<<<<<<     @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    $service, $address,        $proto,   $port,      $status
.

    write LOGCS;

    $service = $servicename;
    $address = $peeraddress;
    $proto = $peerproto;
    $port = $peerport;

    #$address = 'localhost';
    #$proto = 'tcp';
    #$port = '21';

    my $sock = IO::Socket::INET->new(PeerPort  => $port,
                                     Proto     => $proto,
                                     PeerAddr => $address)
                            or $status = "NOT REACHABLE $@";

    if ($sock)
    {
        if ($sock -> connected())
        {
            $status = "REACHABLE";
        }
        else
        {
            $status = "NOT REACHABLE";
        }
    }

    write LOGCS;

    print LOGCS "\n";

    close LOGCS;
}



sub checkntp
{
    header("NTP");

    checkservice("NTP",@ntpservers);

	foreach my $server (@ntpservers)
	{
        #my ($hostname, $ip, $comment) = $address =~ /(\S+)\s+(\S+)\s+(.*)/;
        ($peeraddress, $peerip, $peerproto, $peerport) = split(/:/,$server);

        #print "peeraddress : $peeraddress\n";
        #print "peerip : $peerip\n";
        #print "peerproto : $peerproto\n";
        #print "peerport : $peerport\n";

		data("Testing $hostname ($peerip) 'LDAP'");
	    my $cmd = "$ntptest $peerip";

        #print "cmd : $cmd\n";
	    my @output = getcmdoutput($cmd);
	    data(join("\n",@output));
	}
}

sub checkservice
{
    my ($service,@servers) = @_;

    foreach $server (@servers)
    {
        #print "server : $server\n";
        my ($peeraddress, $peerip, $peerproto, $peerport) = split(/:/,$server);
        #print "peeraddress : $peeraddress\n";
        #print "peerip : $peerip\n";
        #print "peerport : $peerport\n";
        #print "peerproto : $peerproto\n";
        pingchecks("$peeraddress:$peerip:$service");
        checksocket($service,$peerip, $peerproto, $peerport)
    }
}

sub checksmtp
{
    header("SMTP");

    checkservice("SMTP",@mailservers);

    foreach $server (@mailservers)
    {
        #print "server : $server\n";
        my ($hostname, $ip, $peerproto, $peerport) = split(/:/,$server);

		printline("\tTesting $hostname ($ip) 'SMTP server'\n");
	    my $cmd = "$smtptest $ip $mailfrom $rcptto";

	    my @output = getcmdoutput($cmd);
		foreach my $line (@output)
		{
			chop $line;
		    data($line);
		}
	}
}

sub checkldap
{
    header("LDAP");

    checkservice("ldap",@ldapservers);

	foreach my $server (@ldapservers)
	{
		my ($hostname, $ip, $comment) = $address =~ /(\S+)\s+(\S+)\s+(.*)/;
		my ($hostname, $ip, $peerproto, $peerport) = split(/:/,$server);

		#data("Testing $hostname ($ip) '$comment'");
		data("Testing $hostname ($ip) 'LDAP'");


		my $ldapcmd = "$ldaptest -server $ip -secret $ldapsecret -dn $ldapdn -userbase $ldapuserbase -uid $ldaptestuid";
		#print "ldapcmd : $ldapcmd\n";

		my @output = getcmdoutput($ldapcmd);
		data(join("\n","\t",@output));
	}
	checkusers("ldap");
	checkgroups("ldap");
}

sub checkinterfaces
{
    header("INTERFACES");

    my $int = "INT";
    my $mac = "MAC";
    my $status = "STATUS";
    my $slave = "SLAVE";
    my $mtu = "MTU";
    my $rx = "RX";
    my $rxerrors = "ERRORS";
    my $tx = "TX";
    my $txerrors = "ERRORS";

    my @interfacelist;
    my $ifconfigcmd = "ifconfig -a | grep Link | awk '{ print \$1}'";

    open (IF, "$ifconfigcmd |") || die "can not run ifconfig.. : $!\n";
    while(<IF>)
    {
        #print $_;
        chop;
        push @interfacelist, $_;
    }
    close IF;


    open (LOGGI,">>$logfile") || die "can not open logfile($logfile) :$!\n";

		format LOGGI =
    @<<<<<<<<<<  @<<<<<<<<<<<<<<<<  @<<<<<  @<<<<<< @<<<< @<<<<<<<<<<<<<<<  @<<<<<<<<<<<<<<<  @<<<<<<<<<<<<<<<  @<<<<<<<<<<<<<<< 
    $int,     $mac,              $status, $slave,$mtu, $rx,       $rxerrors,$tx,      $txerrors
.


    my @checktypeslist = sort keys %checkints;
    #print "checktypeslist : @checktypeslist\n";

	foreach my $inttype (@checktypeslist)
	{
		#my $entry = 
        #print  "int : $inttype: $entry\n";
        #print LOGGI "  $entry\n";
        print LOGGI "  $inttype\n";

        $int = "INT";
        $mac = "MAC";
        $status = "STATUS";
        $slave = "SLAVE";
        $mtu = "MTU";
        $rx = "RX PKTS";
        $rxerrors = "ERRORS";
        $tx = "TX PKTS";
        $txerrors = "ERRORS";
        write LOGGI;

	    #print "$checkints{$inttype} : @{$checkints{$inttype}}\n";

	  if (ref($checkints{$inttype}) ne 'ARRAY')
		{
			my $item = $checkints{$inttype};
			undef $checkints{$inttype};
			push @{$checkints{$inttype}}, $item;
		}

		#print Dumper $checkints{$inttype};
	    foreach my $interface (@{$checkints{$inttype}})
	    {
            #printline("check $inttype:$interface\n");
            #print STDOUT "check $inttype:$interface\n";

             my (@found) = grep(/^$interface$/, @interfacelist);
             #print "found : @found!\n";

             if (@found)
             {
		my @output = queryinterface($interface);
		#print "1 \@output @output \n";
		$int = shift @output;
		$mac = shift @output;
		$status = shift @output;
		if ($status ne "UP")
		{
			#print " $interface : status : $status\n";
			unshift @output, $status;
			$status = "NO";
		}
		#print "2 \@output @output \n";
		$slave = shift @output;
		if ($slave ne "SLAVE")
		{
			#print " $interface : slave : $slave\n";
			unshift @output, $slave;
			$slave = "NO";
		}
		#print "3 \@output @output \n";

		$mtu = shift @output;
		#print "mtu : $mtu\n";
		$rx = shift @output;
		$rxerrors = shift @output;
		$tx = shift @output;
		$txerrors = shift @output;

                #printline(join(/"\n"/,@output));
                #my ($name, @interfaces) = split(/#/,$line);
                #my $cmd = join(' ', $interfacetest , @interfaces);
                #my $cmd = "$interfacetest $interface";
                #chop(my @output = getcmdoutput($cmd));
                #data(join(/"\n"/,@output));

                write LOGGI;

             }
             else
             {
                 $int = $interface;
                 $mac = "";
                 $status = "NOT";
                 $mtu = "FOUND";
                 $rx = "";
                 $rxerros = "";
                 $tx = "";
                 $txerrors = "";

                write LOGGI;
             }
	    }
        print LOGGI "\n";
	}
    close LOGGI;
}

sub queryinterface
{
    my $int = shift;

    my $querycmd = "ifconfig $int | grep -v inet | grep -v bytes | grep -v collisions | grep -v Interrupt | sed -e 's/RX packets://' -e s'/TX packets://' -e 's/MTU:\*//' -e 's/Metric:[0-9]\*//' -e 's/errors://' -e 's/HWaddr//' -e 's/MULTICAST//' -e 's/BROADCAST//' -e 's/MASTER//' -e 's/RUNNING//' -e 's/Link//' -e 's/encap:Ethernet//' -e 's/dropped:[0-9]\*//' -e 's/frame:[0-9]\*//' -e 's/overruns:[0-9]\*//' -e 's/carrier:[0-9]\*//' | tr \"\\n\" \" \" | tr -s '[:space:]' ' '";

    my $query = `$querycmd`;
    my @results = split (' ',$query);

    return @results;
}


sub checkhostentries
{
    header("HOST FILE");

    my $host = "HOST";
    my $found = "HOST ENTRY";

    open(H, "<$hostfile") || die "can not open host file ($hostfile) : $!\n";
    my @hosts = <H>;
    close H;

    open (LOGCH,">>$logfile") || die "can not open logfile($logfile) :$!\n";

		format LOGCH =
    @<<<<<<<<<<<<<<<<<<<<        @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        $host,   $found
.
    write LOGCH;


    foreach $host (@requiredhosts)
    {
        my @found = grep (/$host/, @hosts);
        $found = shift @found;
        if (!$found)
        {
            #print STDOUT "$host : Not found";
            #data("$host : Not found");
            #printline("$host : Not found");
            $found = "NOT FOUND";
            write LOGCH;
        }
        else
        {
            chop $found;
            write LOGCH;
            #data("$host : -> '$found'");
            #printline("$host : -> '$found'");
            #print STDOUT "$host : -> '$found'";
        }
    }
    #printline("\n");
    close LOGCH;
}

sub standardpingchecks
{
	header("STANDARD PINGS");
    foreach my $server (@standardpings)
    {
        pingchecks($server);
    }
}

sub pingchecks
{
    my @addresses = @_;

	subheader("PING");
    my $host = "HOST";
    my $ip = "IP ADDRESS";
    my $comment = "COMMENT";
    my $status = "STATUS";

    open (LOGP,">>$logfile") || die "can not open logfile($logfile) :$!\n";

		format LOGP =
    @<<<<<<<<<<<<<<<<<<<<<<<    @<<<<<<<<<<<<<<<<<<<<<<    @<<<<<<<<<<<<<<<    @<<<<<<<<<<<<<<<<<
    $host,   $ip,                $comment,            $status
.
        write LOGP;

    #my $p = Net::Ping->new();
    my $p = Net::Ping->new("icmp");

	foreach my $address (@addresses)
	{
		#my ($hostname, $ip, $comment) = $address =~ /(\S+)\s+(\S+)\s+(.*)/;
		($host, $ip, $comment) = split(':',$address);

        #print "ping : $host, $ip, $comment\n";
        #print "ip : '$ip'\n";

        #print  "ping stat : ".$p->ping($host)."\n";
        if ($p->ping($ip))
        {
            $status = "TRUE";
        }
        else
        {
            $status = "FALSE";
        }
        write LOGP;
	}

    print LOGP "\n";

    close LOGP;

    $p->close();
}

sub getcmdoutput
{
    my ($cmd) = @_;

    my @output;

    #print STDOUT "cmd : $cmd\n";
    open (CMD,"$cmd 2>\&1 |") || die "can not run cmd ($cmd) $!\n";
    while (<CMD>)
    {
        #print STDOUT $_;
        push @output, $_;
    }
    close CMD;

    return @output;
}

sub data
{
    my $data = shift;
	printline("    $data\n");
}

sub subheader
{
    my $subheader = shift;
	printline("    $subheader\n");
}

sub header
{
    my $header = shift;
	reportline();
	printline("$header\n");
    reportline();
}

sub printline
{
    my $line = shift;
    open (LOG,">>$logfile") || die "can not open logfile($logfile) :$!\n";
    print LOG $line;
    #print STDOUT $line;
    close LOG;
}

sub reportheader
{
    chop(my $date = `date`);

	header("UNIX SERVER BUILD");
    open (LOG,">>$logfile") || die "can not open logfile($logfile) :$!\n";
    #reportline();
	print LOG "$progname - ";
	print LOG "$progversion\n\n";

    print LOG "-------------------------------------------------------------------------------------------------------------------------------\n";
    print LOG "VALIDATION REPORT: $hostname\n\n";



    print LOG "Date:\t\t$date\n";
    print LOG "Hostname:\t$hostname\n";
    print LOG "Domainname:\t$domainname\n";
    print LOG "OS:\t\t$os\n";
    print LOG "Release:\t$distro\n";
    print LOG "Kernel:\t\t$kernel\n";
    print LOG "Processor:\t$processor\n";
    print LOG "Memory (GB):\t$memtotal\n";
    print LOG "Swap (MB):\t$swap\n";
    print LOG "Swapfile:\t$swapfile\n";

    my $counter = 0;
    foreach my $cpu (@cpus)
    {
        chop $cpu;
        print LOG "CPU$counter:\t\t$cpu\n";
        $counter++;
    }

    close LOG;
}

sub reportipaddresses
{
	header("IP ADDRESSES");
    #print LOG "\n-------------------------------------------------------------------------------\n\n";
    #reportline();
    #print LOG "IP ADDRESSES\n";
    #open (LOG,">>$logfile") || die "can not open logfile($logfile) :$!\n";

    my ($interface,$address,$bcast,$mask);

    $interface = "INTERFACE";
    $address = "ADDRESS";
    $bcast = "BROADCAST";
    $mask = "NETMASK";

    open (LOGIP,">>$logfile") || die "can not open logfile($logfile) :$!\n";

    format LOGIP =
    @<<<<<<<<<    @<<<<<<<<<<<<<<<<    @<<<<<<<<<<<<<<<<    @<<<<<<<<<<<<<<<<
    $interface, $address,            $bcast,              $mask
.
    write LOGIP;

    foreach my $ips (@ipaddresses)
    {
        ($interface,$address,$bcast,$mask) = split(/#/, $ips);

        #if ($bcast)
        #{
            #print LOG "$interface:\t$address\n\tMASK:$mask\n\tBCAST:$bcast\n\n";
        #}
        #else
        #{
            #print LOG "$interface:\t$address\n\tMASK:$mask\n\n";
        #}
        write LOGIP;
    }
    close LOGIP;
}

sub reportline
{

    open (LOG,">>$logfile") || die "can not open logfile($logfile) :$!\n";
    print LOG "-------------------------------------------------------------------------------------------------------------------------------\n";
    close LOG;
}

sub checkopenports
{
    header("Open Ports");

    my ($prot,$address,$port);

    open (LOGOP,">>$logfile") || die "can not open logfile($logfile) :$!\n";

		format LOGOP =
        @<<<<    @<<<<<<<<<<<<<<<    @<<<<<<<<<<<
        $prot,   $address,           $port
.
                        write LOGOP;

    foreach my $portentry (@openports)
    {
        #print "checkportprotocols : @checkportprotocols\n";
        #print "portentry : $portentry\n";
        ($prot,$address,$port) = split(/ /,$portentry);
        #print "prot : $prot\n";
        if (grep (/^$prot$/,@checkportprotocols))
        {
            write LOGOP;
        }
    }
    close LOGOP;

}

sub checkpackages
{
    header("Check Packages");
        my @pkgs = keys %packages;
        open (LOG2,">>$logfile") || die "can not open logfile($logfile) :$!\n";

        my $pkg = shift @checkpkgs;
        #print "checking pkg : $pkg\t\t";

        while ($pkg)
        {

                #print "checking pkg : $pkg\t\t";
                my @found = grep (/^$pkg$/, @pkgs);

                        my $version;
                        my $release;
                        my $arch;

                if (@found)
                {
                        #print "FOUND!\n";
                        $version = $packages{$pkg}{version};
                        $release = $packages{$pkg}{release};
                        $arch = $packages{$pkg}{arch};

                        #print "pkg : $pkg \tversion : $version\trelease : $release\tarch : $arch\n";

		format LOG2 =
        @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<    @<<<<<<<<<<<<<<<<<<<<<    @<<<<<<<<<<<<<<<<<<<    @<<<<<<<<
        $pkg,                          $version,       $release,       $arch
.

                        write LOG2 ;


                }
                else
                {
			$version = "NOT FOUND";
			$release = "";
			$arch = "";

                        #printline("\t$pkg\t\t NOT FOUND!\n\n");
                        write LOG2 ;
                }

                $pkg = shift @checkpkgs;
        }
	close LOG2;
}

sub dumppackages
{
	my @pkgnames = sort keys %packages;
	my $done = 0;

    header("Dump Packages");

	open (LOG,">>$logfile") || die "can not open logfile($logfile) :$!\n";

	while (!$done)
	{
		my $pkg = shift @pkgnames;

		my $version = $packages{$pkg}{version};
		my $release = $packages{$pkg}{release};
		my $arch = $packages{$pkg}{arch};

		#print "pkg : $pkg \tversion : $version\trelease : $release\tarch : $arch\n";

		format LOG =
        @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<    @<<<<<<<<<<<<<<<<<<<<<    @<<<<<<<<<<<<<<<<<<<    @<<<<<<<<
        $pkg,                          $version,       $release,       $arch
.
        #@<<<<<<<<<<<<<<<<<<<<<<<<<<    @<<<<<<<<<<<    @<<<<<<<<<<<    @<<<<<<<<

		write LOG;


		if (!$pkg)
		{
			$done = 1;
		}
	}

	close LOG;
}

sub checkperms
{
	header("PERMISSIONS");
	open (LOGPC,">>$logfile") || die "can not open logfile($logfile) :$!\n";

	my @perms = sort keys %perms;

    my ($path, $chkowner, $chkgroup, $chkpermissions);
    my ($permissions, $owner, $group);

    my $reppath  = "PATH";
    my $repgroup = "GROUP";
    my $repowner = "OWNER";
    my $reppermissions = "PERMS";

    format LOGPC =
        @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  @<<<<<<<  @<<<<<<<  @<<<<<<<<<
        $reppath,                                 $repowner,$repgroup,$reppermissions
.

    write LOGPC;

    foreach my $name (@perms)
    {
        ($path, $chkowner, $chkgroup, $chkpermissions) = @{$perms{$name}};
        my $permcmd = "ls -ld $path  | grep -v \"^total\" | grep -v \"^$path:\" |  awk '{ print \$1 \" \" \$3 \" \" \$4 \" \" \$9 }'";
        #my $permcmd = "ls -Rl $path  | grep -v \"^total\" | grep -v \"^$path:\" |  awk '{ print \$1 \" \" \$3 \" \" \$4 \" \" \$9 }'";
        #print "cmd : $permcmd, $chkowner , $chkgroup , $chkpermissions \n";
        open(CMD,"$permcmd |") || die "Can not run $permcmd : $!\n";
        while (<CMD>)
        {
            chomp;
            ($permissions, $owner, $group, $reppath) = split(/ /,$_);
            $repowner = $owner;
            $repgroup = $group;
            $reppermissions = $permissions;

            write LOGPC;

            $repowner = "CORRECT";
            $repgroup = "CORRECT";
            $reppermissions = "CORRECT";
            my $good = 1;


            #print "path: $path\treppath : $reppath\n";
            #print "permissions : $permissions, owner : $owner , $group\n";
            if ($chkowner ne $owner)
            {
                $repowner = "BAD";
                $good = 0;
            }
            if ($chkgroup ne $group)
            {
                $repgroup = "BAD";
                $good = 0;
            }
            if ($chkpermissions ne $permissions)
            {
                $reppermissions = "BAD";
                $good = 0;
            }
            #print "owner : $repowner, $chkowner->$owner\n";
            #print "group : $repgroup, $chkgroup->$group\n";
            #print "permissions : $reppermissions, $chkpermissions->$permissions\n";
            my $length = length($reppath);
            if ($length => 50)
            {
                $reppath = substr $reppath, -50;
            }

            write LOGPC;
            
            if (!$good)
            {
                $reppath = "SHOULD BE";
                $repowner = "$chkowner";
                $repgroup = "$chkgroup";
                $reppermissions = "$chkpermissions";
                write LOGPC;
            }
                print LOGPC "\n";
        }
        #print "\n";
        close CMD;
    }
        close LOGPC;
}

sub checkusers
{
	my ($type) = @_;

	my $isldap = 0;


	if ($type eq "ldap")
	{
		$isldap = 1;
		subheader("USER(LDAP)");
	}
	else
	{
		header("USER(LOCAL)");
	}


    open (LOGUC,">>$logfile") || die "can not open logfile($logfile) :$!\n";

    my @users;
    my @checkusers;

	if ($isldap)
	{ 
		@users = sort keys %ldapusers;
		foreach my $u (@checkldapusers)
		{
			#@checkusers = sort keys %ldapcheckusers;
			my ($user,@blah) = split (':',$u);
			push @checkusers,$user;
		}
	}
	else
	{
		@users = sort keys %users;
		@checkusers = sort keys %checkusers;
	}


    my ($user, $uid, $group, $home, $shell);

    my $repuser = "USER";
    my $repuid = "UID";
    my $repgroup = "GROUP";
    my $rephome = "HOME";
    my $repshell  = "SHELL";

            format LOGUC =
        @<<<<<<<<<<<    @<<<<<<<<<<<<    @<<<<<<<<    @<<<<<<<<<<<<<<<<<<<<<<<<<    @<<<<<<<<<<<<<<<<<<<<<
        $repuser,       $repuid,         $repgroup,  $rephome,   $repshell
.

    write LOGUC;

    foreach $user (@checkusers)
    {

        #print "user : $user\n";
        if (grep (/^$user$/,@users))
        {
            my ($uid, $group, $home, $shell);
            my ($chkuid, $chkgroup, $chkhome, $chkshell);

	if ($isldap)
	{
            ($uid, $group, $home, $shell) = split(/:/,$ldapusers{$user});
		#print "\@checkldapusers : @checkldapusers\n";
		my ($u) = grep(/^$user/,@checkldapusers);
		#print "user : $user\tu : $u\n";
		my $blah;
            ($blah, $chkuid, $chkgroup, $chkhome, $chkshell) = split (':',$u);
	}
	else
	{
            ($uid, $group, $home, $shell) = split(/:/,$users{$user});
            ($chkuid, $chkgroup, $chkhome, $chkshell) = @{$checkusers{$user}};
	}

	#print "$isldap : ($uid, $group, $home, $shell)\n";
	#print "$isldap : ($chkuid, $chkgroup, $chkhome, $chkshell)\n";


            $repuser = $user;
            $repuid = $uid;
            $repgroup = $group;
            $rephome = $home;
            $repshell = $shell;
            write LOGUC;

            $repuser = "";
            $repuid = "CORRECT";
            $repgroup = "CORRECT";
            $rephome = "CORRECT";
            $repshell = "CORRECT";

            my $good = 1;

            if ($chkuid ne $uid)
            {
                $repuid = "BAD";
                $good = 0;
            }
            if ($chkgroup ne $group)
            {
                $repgroup = "BAD";
                $good = 0;
            }
            if ($chkhome ne $home)
            {
                $rephome = "BAD";
                $good = 0;
            }
            if ($chkshell ne $shell)
            {
                $repshell = "BAD";
                $good = 0;
            }
            #print "owner : $repowner, $chkowner->$owner\n";
            #print "group : $repgroup, $chkgroup->$group\n";
            #print "permissions : $reppermissions, $chkpermissions->$permissions\n";

            write LOGUC;
            if (!$good)
            {
                $repuser = "SHOULD BE";
                if ($repuid eq "BAD")
                {
                    $repuid = "$chkuid";
                }
                else
                {
                    $repuid = "";
                }
                if ($repgroup eq "BAD")
                {
                    $repgroup = "$chkgroup";
                }
                else
                {
                    $repgroup = "";
                }
                if ($rephome eq "BAD")
                {
                    $rephome = "$chkhome";
                }
                else
                {
                    $rephome = "";
                }
                if ($repshell eq "BAD")
                {
                    $repshell = "$chkshell";
                }
                else
                {
                    $repshell = "";
                }

                write LOGUC;
                print LOGUC "\n";
            }
        }
        else
        {
            $repuser = $user;
            $repuid = "NOT FOUND";
            $repgroup = "";
            $rephome = "";
            $repshell = "";
            write LOGUC;
            print LOGUC "\n";
        }
    }
    close LOGUC;
}


sub checkgroups
{
	my ($type) = @_;
	my $isldap = 0;



	if ($type eq "ldap")
	{
		$isldap = 1;
		subheader("GROUP(LDAP)");
	}
	else
	{
		header("GROUP(LOCAL)");
	}


    open (LOGGC,">>$logfile") || die "can not open logfile($logfile) :$!\n";

    my @groups;
    my @checkgroups;

	if ($isldap)
	{ 
		@groups = sort keys %ldapgroups;
		foreach my $g (@checkldapgroups)
		{
			#@checkusers = sort keys %ldapcheckusers;
			my ($group,@blah) = split (':',$g);
			#print "$isldap :g = $g\n";
			#print "$isldap :group = $group\n";
			push @checkgroups,$group;
		}
	}
	else
	{
		@groups = sort keys %groups;
		@checkgroups = sort keys %checkgroups;
	}

	#print "checkgroup : @checkgroups\n";

    my ($group, $gid, @users);

    my $repgroup = "GROUP";
    my $repgid = "GID";
    my $repusers = "USERS";

            format LOGGC =
        @<<<<<<<<<<<    @<<<<<<<<<<<<    @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        $repgroup,      $repgid,         $repusers
.

    write LOGGC;

    foreach $group (@checkgroups)
    {

        #print "$isldap : group : $group\n";
        if (grep (/^$group$/,@groups))
        {
            my ($gid, $users);
            my ($chkgid, @chkusers);
            my $chkusers;

	if ($isldap)
	{
            ($gid, $users) = split(/:/,$ldapgroups{$group});
		#print "gid : $gid\n";
		#print "users : $users\n";
		my ($g) = grep(/^$group/,@checkldapgroups);
		#print "group : $group\tg : $g\n";
		my $blah;
            ($blah, $chkgid, $chkusers) = split (':',$g)
	}
	else
	{

            ($gid, $users) = split(/:/,$groups{$group});
            ($chkgid, $chkusers) = @{$checkgroups{$group}};
	}

		#print "group $group : $gid, $users\n";
		#print "chk group $group : $chkgid, $chkusers\n";


            $repgroup = $group;
            $repgid = $gid;
            $repusers = $users;

            write LOGGC;

            $repgroup = "";
            $repgid = "CORRECT";
            $repusers = "CORRECT";

            my $good = 1;

            if ($chkgid ne $gid)
            {
                $repgid = "BAD";
                $good = 0;
            }
            if ($chkusers ne $users)
            {
                $repusers = "BAD";
                $good = 0;
            }

            write LOGGC;
            if (!$good)
            {
                $repgroup = "SHOULD BE";
                if ($repgid eq "BAD")
                {
                    $repgid = "$chkgid";
                }
                else
                {
                    $repgid = "";
                }
                if ($repusers eq "BAD")
                {
                    $repusers = "$chkusers";
                }
                else
                {
                    $repusers = "";
                }

                write LOGGC;
                print LOGGC "\n";
            }
        }
        else
        {
            $repgroup = $group;
            $repgid = "NOT FOUND";
            $repusers = "";
            write LOGGC;
                print LOGGC "\n";
        }
    }
    close LOGGC;
}

sub checkkernelparams
{
	my @kernelparams = sort keys %kernelparams;

	my $pkg = shift @checkpkgs;

	header("KERNEL PARAMETERS");

	open (LOGKP,">>$logfile") || die "can not open logfile($logfile) :$!\n";

	my $checkparam = shift @checkkernelparams;
	while ($checkparam)
	{
		 #print "checking param : $checkparam\t\t";
                my @found = grep (/^$checkparam$/, @kernelparams);

		my $val;
                if (@found)
                {
                        #print "FOUND!\n";

			$val = $kernelparams{$checkparam};
			#print "param : $checkparam \tval : $val\n";
			format LOGKP =
        @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<    @<<<<<<<<<<<<<<<<<<<<<
        $checkparam,                   $val   
.

			write LOGKP;
		}
		else
		{
			$val = "NOT FOUND";
			#printline("\t$checkparam\t\t\tNOT FOUND!\n");
			write LOGKP;
		}

		$checkparam = shift @checkkernelparams;
	}

	close LOGKP;
}

sub dumpkernelparams
{
	my @kernelparams = sort keys %kernelparams;

    header("Dump Kernel Parameters");

	open (LOGK,">>$logfile") || die "can not open logfile($logfile) :$!\n";

	my $param = shift @kernelparams;
	while ($param)
	{

		my $val = $kernelparams{$param};
		#print "param : $param \tval : $val\n";
		format LOGK =
        @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<    @<<<<<<<<<<<<<<<<<<<<<
        $param,                        $val
.

		write LOGK;

		$param = shift @kernelparams;
	}

	close LOGK;
}


exit 0;
