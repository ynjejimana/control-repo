#! /usr/bin/perl -w
#### Monitoring HP Hardware with ESXi (WBEM)
####### Config ##############
my $IP;
if (!defined($ARGV[0])) {$IP="172.16.38.103"}
  else {$IP=$ARGV[0]} 
my $password;
if (!defined($ARGV[1])) {$password="XXXXXXX"} 
  else {$password=$ARGV[1]}
my $username;
if (!defined($ARGV[2])) {$username="root"}
  else {$username=$ARGV[2]}

my $statusfile="/tmp/vmware_$IP.txt";

my $wbemcli="/usr/bin/wbemcli -nl ei -noverify http://$username:$password\@$IP/root/cimv2:";
# "WBEM_CLASS" =>["Name_of_hardware","Status_hardware","Status1_hardware","Status2_hardware"]
my %WBEM=(
	"CIM_NumericSensor" =>["ElementName","CurrentReading"]
	,"CIM_FAN"		=>["ElementName","OperationalStatus"]
	,"CIM_Processor"	=>["ElementName","OperationalStatus"]
	,"CIM_Memory"		=>["ElementName","OperationalStatus"]
	,"CIM_PowerSupply"=>["ElementName","OperationalStatus"]
	,"CIM_DiskDrive"=>["ElementName","HealthState"]
);
# "WBEM_CLASS" =>("Status_hardware"=>"New_Name_of_sensor")
#NEW_NAME if "Status_hardware" 
my %REPLASE=(
#	"CIM_NumericSensor"=>{"CurrentReading"=>"Temperature"},
#	"SMX_SAArraySystem"=>{"OperationalStatus"=>"Array"}
);
$TIMEOUT=20;
# error_code
# 0 - Ok
# 1 - error with wbem client
# 2 - error with status file. Can't write status file.
# 3-  Invalid username/password.
# 4 - Can't connect to ESXi. 
# 5 - Can't get data from ESXi.
####### End Config ##########
my %RESULT;
my $i;
my $code;
my $error_code=0;
#debugging - autoflush stdout
#$| = 1;
$SIG{ALRM}=sub{die "Timeout $TIMEOUT sec"};
eval {
alarm($TIMEOUT);
foreach $i (keys %WBEM)
 {
 $code=get_wbem(WBEM_CLASS=>$i,STATUS=>$WBEM{$i});
 if ($code>0) {$error_code=$code; print "$error_code\n"; exit(0);};
 }
foreach $i (keys %RESULT)
 {
 $code=Write_Status(FILE=>"$statusfile",NAME=>"$i",STATUS=>"$RESULT{$i}");
 if ($code==1) {$error_code=2};
 }
alarm(0);
};
if ($@) {$error_code=1 };
print "$error_code\n";

sub get_wbem
 {
  my %args=(
    WBEM_CLASS=>"",
    STATUS=>["DeviceID","OperationalStatus"],
    @_);
 my $error=0;
 my $name;
 my $data;
 my %hardware;
 my %DEVICE_NAME;
 my $index=0;
 my $count=0;
 my $prog=$wbemcli.$args{WBEM_CLASS};
 my $i;
 my $array=$args{STATUS};
 my @KEY=(@$array);
 open(DF, "$prog 2>&1|") || ($error=1);
 while(<DF>)
  {
  chop;
  if (/Invalid username/) {$error=3; return $error;}
  if (/Http Exception:/) {$error=4; return $error;}
  if(/^-(.+?)=(.+?)$/) 
    {
	$count++;
	$name=$1;
	$data=$2;
	$data=~s/ /_/g;
	$data=~s/"//g;
	$data=~s/:/_/g;
	foreach $i (@KEY)
         {
	 if ($i eq "") {next;}
	 if ($name eq $i) 
		{
		if ($name eq $args{STATUS}[0]) 
		 {
		 $DEVICE_NAME{$i}=$data;
    		 }else{
		      $hardware{$i}=$data;
		      }
		}
         }
	}
  if(/^-(.+?)$/) 
    	{
	$count++;
	$name=$1;
	$data=0;
	foreach $i (@KEY)
         {
         if ($i eq "") {next;}
         if ($name eq $i)
                {
                if ($name eq $args{STATUS}[0])
                 {
                 $DEVICE_NAME{$i}=$data;
                 }else{
                      $hardware{$i}=$data;
                      }
                }
         }
	}
  if (/^$/) 
	{
	 foreach $i (keys %hardware)
  	  {
	  if (defined $REPLASE{$args{WBEM_CLASS}}{$i})
	   {
	    $RESULT{$REPLASE{$args{WBEM_CLASS}}{$i}."_".$index}=$hardware{$i};
	    $index++;
	   }else{
	       $RESULT{$DEVICE_NAME{$args{STATUS}[0]}}=$hardware{$i}; 
		}
	  }
	%hardware=();  
	}
  }
 close(DF);
 if ($count==0) {$error=5}
 return $error;
 }

sub Write_Status
{
 my %args=(
    FILE=>"",
    NAME=>"",
    STATUS=>"",
    @_);
local *FILE;
my $i;
my $error=0;
my %hash=();
if (!(-f $args{FILE}))
                {
                 open(FILE,">$args{FILE}")|| ($error=1);
                 close(FILE);
                }
%hash=Read_Status(FILE=>"$args{FILE}");
$hash{$args{NAME}}=$args{STATUS};
open(FILE,">$args{FILE}")|| ($error=1);
foreach  $i (keys(%hash))
 {
 print FILE "$i:\t$hash{$i}\n";
 }
close(FILE);
return $error;
}

sub Read_Status
{
my %args=(
    FILE=>"",
    @_);
local *FILE;
my ($name,$status);
my %hash=();
if (!(-f $args{FILE})) 
		{
		 open(FILE,">$args{FILE}");
		 close(FILE);
		}
open(FILE,"$args{FILE}");
while(<FILE>)
 {
 chop;
 ($name,$status)=split(/\t+/,$_,2);
 $name=~s/://g;
 $hash{$name}=$status;
 }
close(FILE);
return %hash;
}
 
