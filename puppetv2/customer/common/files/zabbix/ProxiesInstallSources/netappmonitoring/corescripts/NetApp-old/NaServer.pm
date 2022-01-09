#============================================================#
#                                                            #
# $ID:$                                                      #
#                                                            #
# NaServer.pm                                                #
#                                                            #
# Client-side interface to ONTAPI APIs                       #
#                                                            #
# Copyright 2002-2003 Network Appliance, Inc. All rights     #
# reserved. Specifications subject to change without notice. #
#                                                            #
# This SDK sample code is provided AS IS, with no support or #
# warranties of any kind, including but not limited to       #
# warranties of merchantability or fitness of any kind,      #
# expressed or implied.  This code is subject to the license #
# agreement that accompanies the SDK.                        #
#                                                            #
# tab size = 8                                               #
#                                                            #
#============================================================#

package NaServer;

$VERSION = '1.0';	# work with all versions

use	Socket;
use	LWP::UserAgent;
use	XML::Parser;
eval	"require	Net::SSLeay";
use	NaElement;
use Net::SSLeay qw(die_now die_if_ssl_error) ;

# use	vars ('@ISA', '@EXPORT');
# use	Exporter;

# @ISA	= qw(Exporter);
# @EXPORT	= qw(invoke);
# @EXPORT	= qw(invoke_elem);

my $ctx = "";
my $chk_ssl_init = 0;

#============================================================#

=head1 NAME

  NaServer - class for managing Network Appliance(r)
             filers using ONTAPI(tm) APIs.


=cut

=head1 DESCRIPTION

  An NaServer encapsulates an administrative connection to
  a NetApp filer running ONTAP 6.4 or later.  You construct
  NaElement objects that represent queries or commands, and
  use invoke_elem() to send them to the filer (a convenience 
  routine called invoke() can be used to bypass the element
  construction step.  The return from the call is another
  NaElement which either has children containing the command
  results, or an error indication.
  
  The following routines are available for setting up 
  administrative connections to a filer.

=cut

#============================================================#

use	strict;

$::ZAPI_xmlns = "http://www.netapp.com/filer/admin";
$::ZAPI_dtd = "file:/etc/netapp_filer.dtd";
$::ZAPI_snoop = 0;

#============================================================#

=head2  new($filer, $majorversion, $minorversion)

  Create a new connection to filer $filer.  Before
  use, you either need to set the style to "hosts.equiv"
  or set the username (always "root" at present) and
  password with set_admin_user().

=cut

sub new {
	my ($class)  = shift;
	my ($server) = shift;
	my ($major_version) = shift;
	my ($minor_version) = shift;
	my ($user)   = "root";
	my ($password) = "";
	my ($style) = "HOSTS";	# LOGIN or HOSTS
	my ($port)  = 443;
    my ($vfiler) = "";

	my $self = {
		server => $server,
		user   => $user,
		password => $password,
		style => $style,
		major_version => $major_version,
		minor_version => $minor_version,
		transport_type => "HTTPS",
		port => $port,
		vfiler => $vfiler
	};

	bless $self, $class;

	$self->set_server_type("FILER");
	return $self;
}

#============================================================#

=head2 set_style($style)

  Pass in "LOGIN" to cause the server to use HTTP 
  simple authentication with a username and 
  password.  Pass in "HOSTS" to use the hosts.equiv 
  file on the filer to determine access rights (the
  username must be root in that case).

=cut

sub set_style ($) {
	my $self = shift;
	my $style = $self->{style};

	if ($style ne "HOSTS" && $style ne "LOGIN") {
		return $self->fail_response(13001,
			"in NaServer::set_style: bad style \"$style\"");
	}
	$self->{style} = shift;
}

#============================================================#

=head2 get_style()

  Get the authentication style

=cut

sub get_style () {
	my $self = shift;

	return $self->{style};
}

#============================================================#

=head2 set_admin_user($user, $password)

  Set the admin username and password.  At present
  $user must always be "root".

=cut

sub set_admin_user ($$) {
	my $self = shift;

	$self->{user} = shift;
	$self->{password} = shift;
}

#============================================================#

=head2 set_server_type($type)

  Pass in one of these keywords: "FILER" or "NETCACHE"
  to indicate whether the server is a filer or a NetCache
  appliance.

  If you also use set_port(), call set_port() AFTER calling
  this routine.

  The default is "FILER".

=cut

#
#  Note that "AGENT" and "DFM" are also valid values.  We
#  don't expose those to customers yet.
#

sub set_server_type ($$) {
	my $self = shift;
	my $type = shift;
	my $port = $self->{port};

	if ($type !~ /^(Filer|NetCache|Agent|DFM)/i) {
		return $self->fail_response(13001,
		  "in NaServer::set_server_type: bad type \"$type\"");
	}

	($type =~ /Filer/i) && do {
		$self->{url} = "/servlets/netapp.servlets.admin.XMLrequest_filer";
	};
	($type =~ /NetCache/i) && do {
		$self->{url} = "/servlets/netapp.servlets.admin.XMLrequest";
		$self->{port} = 80;
	};
	($type =~ /Agent/i) && do {
		$self->{url} = "/apis/XMLrequest";
		$self->{port} = 4092;
	};
	($type =~ /DFM/i) && do {
		$self->{url} = "/apis/XMLrequest";
		$self->{port} = 8081;
	};

	$self->{servertype} = $type;
}

#============================================================#

=head2 get_server_type()

  Get the type of server this server connection applies to.

=cut

sub get_server_type () {
	my $self = shift;

	return $self->{servertype};
}

#============================================================#

=head2 set_transport_type($scheme)

  Override the default transport type.  The valid transport
  type are currently "HTTP", "HTTPS".

=cut

sub set_transport_type ($$) {
	my $self = shift;
	my $scheme = shift;

	if ($scheme ne "HTTP" && $scheme ne "HTTPS") {
		return $self->fail_response(13001,
		  "in NaServer::set_transport_type: bad type \"$scheme\"");
	}
	if ($scheme eq "HTTP") {
	
		$self->{transport_type} = "HTTP";
		$self->{port} = 80;
	}
	if ($scheme eq "HTTPS") {
	
		$self->{transport_type} = "HTTPS";
		$self->{port} = 443;

		#One time SSL initialization
		if (!$chk_ssl_init) {

			Net::SSLeay::load_error_strings();
			Net::SSLeay::SSLeay_add_ssl_algorithms();
			#Random seed.
			Net::SSLeay::randomize("", time ^ $$);
			$ctx = Net::SSLeay::CTX_new() or
			return $self->fail_response(13001,
				"in Zapi::new - failed to create SSL_CTX ");
			Net::SSLeay::CTX_set_options($ctx, &Net::SSLeay::OP_ALL)
			and die_if_ssl_error("ssl ctx set options");
			$chk_ssl_init = 1;

		}
	}

}

#============================================================#

=head2 get_transport_type()

  Retrieve the transport used for this connection.

=cut

sub get_transport_type () {
	my $self = shift;

	return $self->{transport_type};
}


#============================================================#

=head2 set_port($port)

  Override the default port for this server.  If you
  also call set_server_type(), you must call it before
  calling set_port().

=cut

sub set_port ($$) {
	my $self = shift;
	my $port = shift;

	$self->{port} = $port;
}

#============================================================#

=head2 get_port()

  Retrieve the port used for the remote server.

=cut

sub get_port () {
	my $self = shift;

	return $self->{port};
}


#============================================================#

=head2 use_https()

   Determines whether https is enabled.

=cut

sub use_https () {
	my $self = shift;
	if ($self->{transport_type} eq "HTTPS" ) {
		return 1;
	} else {
		return 0;
	}
}
#============================================================#

=head2 invoke_elem($elt)

  Submit an XML request already encapsulated as
  an NaElement and return the result in another 
  NaElement.

=cut

sub invoke_elem ($) {
	my $self	= shift;
	my $req		= shift;

	my $server	= $self->{server};
	my $user	= $self->{user};
	my $password	= $self->{password};
    my $vfiler  = $self->{vfiler};

	#my $xmlrequest = $req->sprintf();
	my $xmlrequest = $req->toEncodedString();

        # This is the filer url, in a form acceptable
	# to the method line of an HTTP transaction.

        my $url = $self->{url};

	my($sockaddr);
	my($name,$aliases,$proto,$port,$type,$len,$thisaddr);
	my($thisport,$thatport);
	my($thataddr);

	my $using_ssl = $self->use_https();
	my $ssl;
	
	#
	# Establish socket connection
	#
	$sockaddr = 'S n a4 x8';
	if ($using_ssl) {
	    ($name,$aliases,$proto)=getprotobyname('ssl');
	     $proto = 0;
 	} else {	
	    ($name,$aliases,$proto)=getprotobyname('tcp');
	}

	($name,$aliases,$type,$len,$thataddr)=gethostbyname($server);
	$thatport=pack($sockaddr, &AF_INET,$self->{port},$thataddr);
	if ( !socket(S, &PF_INET,&SOCK_STREAM,$proto) ) {
		return $self->fail_response(13001,
			"in Zapi::invoke, cannot create socket");
	}
	#
	# If we are being asked to use a reserved port (we
	# are doing hosts.equiv authentication), then we search to
	# find an available port number below 1024.
	#
	if ( $self->get_style() eq "HOSTS" ) {
		my $lowport;
		for ($lowport=1023; $lowport > 0; $lowport--) {
			$thisport=pack($sockaddr, &AF_INET,$lowport);
			if (bind(S,$thisport)) {
				last;
			}
		}
		if ($lowport == 0) {
			return $self->fail_response(13001,
				"in Zapi::invoke, unable to bind "
				."to reserved port, you must be "
				."executing as root");
		}
	} else {
		$thisport=pack($sockaddr, &AF_INET,0);
		if (!bind(S,$thisport)) {
			return $self->fail_response(13001,
				"in Zapi::invoke, unable to bind to port");
		}
	}

	if ( ! connect(S,$thatport) ) {
		return $self->fail_response(13001,
			"in Zapi::invoke, cannot connect to socket");
	}
	select(S); $| = 1;              # Turn on autoflushing
	select(STDOUT); $| = 1;         # Select STDOUT as default output
	
        #
	# Create an HTTP request.
        #
	my $request = HTTP::Request->new('POST',"$url");
	
	$request->authorization_basic($user,$password);
	my $content = "";
    my $vfiler_req = "";
    
    if($vfiler ne "") {
        $vfiler_req = " vfiler= \"$vfiler\" ";
    }

    $content = "<?xml version='1.0' encoding='utf-8' ?>"
		."<!DOCTYPE netapp SYSTEM '$::ZAPI_dtd'>"
		."<netapp"
        .$vfiler_req
        ." version='"
		.$self->{major_version}.".".$self->{minor_version}
		."' xmlns='$::ZAPI_xmlns'>"
		.$xmlrequest
		."</netapp>";

    
	$request->content($content);
	$request->content_length(length($content));

	my $methline =  $request->method()." ".$request->uri()." HTTP/1.0\n";
	my $headers  =  $request->headers_as_string();

	if ($using_ssl) {
		$ssl = Net::SSLeay::new($ctx) or return $self->fail_response(13001,
			"in Zapi::invoke, failed to create SSL $!");
		Net::SSLeay::set_fd($ssl, fileno(S)); #Must use fileno
		Net::SSLeay::connect($ssl) or return $self->fail_response(13001,
		     "in Zapi::invoke failed to connect SSL $!");
				
		Net::SSLeay::ssl_write_all($ssl, $methline);
		Net::SSLeay::ssl_write_all($ssl, $headers);
		Net::SSLeay::ssl_write_all($ssl, "\n");
		Net::SSLeay::ssl_write_all($ssl, $request->content());

	} else {
		print S $methline;
		print S $headers;
		print S "\n";
		print S $request->content();
	}

	my $xml = "";
	my $response;

	# Inside this loop we will read the response line and all headers
	# found in the response.

	my $n;
	my $state = 0;	# 1 means we're in headers, 2 means we're in content
	my ($key, $val);
	my $line;
	while (1) {
		if ($using_ssl) {
		    $line = Net::SSLeay::ssl_read_CRLF($ssl);
#print "-->$line\n";
		} else {	
		    $line = <S>;
		}

		if ( !defined($line) || $line eq "" ) {
			last;
		}
		if ( $state == 0 ) {
			if ($line =~ s/^(HTTP\/\d+\.\d+)[ \t]+(\d+)[ \t]*([^\012]*)\012//) {
				# HTTP/1.0 response or better
				my($ver,$code,$msg) = ($1, $2, $3);
				$msg =~ s/\015$//;
				$response = HTTP::Response->new($code, $msg);
				$response->protocol($ver);
				$state = 1;
				next;
			} else {
				return $self->fail_response(13001,
					"in Zapi::invoke, unable to parse "
					."status response line - $line");
			}
		} elsif ( $state == 1 ) {
			# ensure that we have read all headers.
			# The headers will be terminated by two blank lines
			if ( $line =~ /^\r*\n*$/ ) {
				$state = 2;
			} else {
				if ($line =~ /^([a-zA-Z0-9_\-.]+)\s*:\s*(.*)/) {
					$response->push_header($key, $val) if $key;
					($key, $val) = ($1, $2);
				} elsif ($line =~ /^\s+(.*)/ && $key) {
					$val .= " $1";
				} else {
					$response->push_header(
					    "Client-Bad-Header-Line" => $line);
				}
			}
		} elsif ( $state == 2 ) {
			$xml .= $line;
		} else {
			return $self->fail_response(13001,
				"in Zapi::invoke, bad state value "
				."while parsing response - $state\n");
		}
	}

	if ($using_ssl) {
   	  Net::SSLeay::free ($ssl);  			# Tear down connection
	}	

	if ( ! defined($response) ) {
		$self->{fail}->("No response received?");
		$xml = "<results reason=\"No response received\" "
				."status=\"failed\" errno=\"13001\" />";
	}
	my $code = $response->code();
	if ( $code == 401 ) {
		return $self->fail_response(13002,"Authorization failed");
	}

	return $self->parse_xml($xml,$xmlrequest);
}

#============================================================#

=head2 invoke($api, [$argname, $argval] ...)

   A convenience routine which wraps invoke_elem().
   It constructs an NaElement with name $api, and
   for each argument name/value pair, adds a child
   element to it.  It's an error to have an even
   number of arguments to this function.  

   Example: $myserver->invoke("snapshot-create",
                              "snapshot", "mysnapshot",
			      "volume", "vol0");

=cut

sub invoke (@) {
	my $self = shift;
	my $api  = shift;

	my $num_parms = @_;
	my $i;
	my $key;
	my $value;

	if ( ($num_parms & 1) != 0 ) {
		return $self->fail_response(13001,
			"in Zapi::invoke, invalid number of parameters");
	}

	my $xi = new NaElement($api);

	for ($i = 0; $i < $num_parms; $i += 2) {
		$key = shift;
		$value = shift;
		$xi->child_add(new NaElement($key, $value));
	}

	return $self->invoke_elem($xi);
}

1;

=head1 COPYRIGHT

  Copyright 2002-2003 Network Appliance, Inc. All rights 
  reserved. Specifications subject to change without notice.

  This SDK sample code is provided AS IS, with no support or 
  warranties of any kind, including but not limited to 
  warranties of merchantability or fitness of any kind, 
  expressed or implied.  This code is subject to the license 
  agreement that accompanies the SDK.

=cut

###############################################################################

# "private" subroutines for use by the public routines

#
# This is used when the transmission path fails, and we don't actually
# get back any XML from the server.
#
sub fail_response {
	my $self	= shift;
	my $errno	= shift;
	my $reason	= shift;

	my $n = new NaElement("results");
	$n->attr_set("status","failed");
	$n->attr_set("reason","$reason");
	$n->attr_set("errno","$errno");
	return $n;
}


sub server_start_handler ($$@) {
	my $xp = shift;
	my $el = shift;

	my $n = new NaElement("$el");
	push(@$::ZAPI_stack,$n);

	my $sz = $#$::ZAPI_stack;

	%::ZAPI_atts = ();
	while ( @_ ) {
		my $att = shift;
		my $val = shift;
		$::ZAPI_atts{$att} = $val;
		$n->attr_set($att,$val);
	}
}

sub server_char_handler {
	my $xp = shift;
	my $data = shift;

	my $i = $#$::ZAPI_stack;
	$::ZAPI_stack->[$i]->add_content($data);
}

sub server_end_handler {
	my $xp = shift;
	my $el = shift;

	# We leave the last element on the stack.
	if ( $#$::ZAPI_stack > 0 ) {
		my $sz = $#$::ZAPI_stack;

		# Pop the element and add it as a child
		# to its parent.
		my $n = pop(@$::ZAPI_stack);
		my $ns = $n->sprintf();
		my $i = $#$::ZAPI_stack;

		$::ZAPI_stack->[$i]->child_add($n);
	}
}

# this is a helper routine for invoke_elem

sub parse_xml {

	my $self	= shift;
	my $xml		= shift;
	my $xmlrequest	= shift;

	$::ZAPI_stack = [];

	my $p = new XML::Parser(ErrorContext => 2);
	$p->setHandlers(
		Start => \&server_start_handler,
		Char => \&server_char_handler,
		End => \&server_end_handler
		);
	$p->parse($xml);

	if ( $#$::ZAPI_stack < 0 ) {
		return $self->fail_response(13001,
			"Zapi::parse_xml - no elements on stack");
	}
	my $r = pop(@$::ZAPI_stack);

	if ( $r->{name} ne "netapp" ) {
		return $self->fail_response(13001,
			"Zapi::parse_xml - Expected <netapp> element, "
			."but got ".$r->{name});
	}

	my $results = $r->child_get("results");
	if (! defined($results)) {
		return $self->fail_response(13001,
			"Zapi::parse_xml - No results element in output!");
	}
	return $results;
}

#============================================================#

=head2 set_vfiler($vfiler)

  sets the vfiler name. This function is added for vfiler-tunneling.

=cut

sub set_vfiler ($$) {
	my $self = shift;
	my $vfname = shift;

    if($self->{major_version} >= 1) {
        if($self->{minor_version} >= 7) {
            $self->{vfiler} = $vfname;
            return 1;
        }
    }
    return 0;
}


