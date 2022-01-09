#!/usr/bin/perl -w
#### Monitoring  ESXi (VMware Infrastructure (VI) API.)
#### Dmitry Maksimov dima_dm@hotmail.com 12.01.2010
####### Config ##############
my $IP;
if (!defined($ARGV[0])) {$IP="172.16.38.103"}
  else {$IP=$ARGV[0]}
my $password;
if (!defined($ARGV[1])) {$password='XXXXXXX'}
  else {$password=$ARGV[1]}
my $username;
if (!defined($ARGV[2])) {$username="root"}
  else {$username=$ARGV[2]}
my $service_url = "https://".$IP."/sdk";
my $statusfile="/tmp/vmware_api_$IP.txt";
# key =>data
my %API=(
	"CpuTotal"	=>0
	,"CpuUsed"	=>0
	,"MemSize"	=>0
	,"MemUsage"	=>0
	,"MaintenanceMode"=>0
);

my %ARRAY=();

# error_code
# 0 - Ok
# 1 - error with perl API
# 2 - error with status file. Can't write status file.
# 3 - bad username or password
####### End Config ##########
use strict;
use warnings;
use lib "/usr/lib/vmware-vcli/apps/";

use VMware::VIRuntime;
use VMware::VICommon;
use VMware::VIExt;
my $i;
my $code;
my $error_code=0;

#debugging - autoflush stdout
$| = 1;

if ($#ARGV < 0) {
	$error_code=1;
	print "$error_code\n";
        exit 0;
}

eval {
# Login to Virtual Center service:
my $retval =Vim::login(service_url => $service_url, user_name => $username, password => $password);
      };
      if ($@) 
	{
          if ($@ =~ /incorrect user name or password/) {
            $error_code=3;            
         } else {
           $error_code=1;
         }
       }
if  ($error_code>0) { print "$error_code\n"; exit 0; }
my $host = Vim::find_entity_view(
view_type => 'HostSystem',
properties => [ 'summary' ],
);

my ($cpuMhz, $numCores);
my $summary = $host->get_property("summary");

$cpuMhz = $summary->hardware->cpuMhz;
$numCores = $summary->hardware->numCpuCores;
$API{CpuTotal} = $cpuMhz * $numCores * 1000000; #in hz
$API{CpuUsed} = $summary->quickStats->overallCpuUsage * 1000000; #in hz
$API{MemSize} = $summary->hardware->memorySize; # in Byte
$API{MemUsage} = $summary->quickStats->overallMemoryUsage * 1048576 ; # in Byte

my $host_view = VIExt::get_host_view(1);
my $datastoreRefs = $host_view->datastore;
my $mounts = $host_view->config->fileSystemVolume->mountInfo;
my @datastores = ();
   foreach (@$datastoreRefs) {
      my $datastore = Vim::get_view(mo_ref => $_);
      push (@datastores, $datastore);
   }
foreach (@$mounts)
 {
 my $type = "";
 my $name = "";
 my $UUID = "";
 my $capacity = "";
 my $free = "??";
 my $partition = "";
 my $partitions = "";
 my $diskName;
 my $vol;
 my $info;
 my $extents;
 my $numExtents = 0;
 $info = $_->mountInfo;
 $vol = $_->volume;
 $name = $vol->{name} if $vol->{name};
 my $info_path = $info->path;
      $info_path =~ s/\/vmfs\/volumes\///;
      $capacity = $vol->capacity;
      foreach (@datastores) {
         if ($_->info->url =~ /$info_path/) {
            $free = $_->info->freeSpace;
         }
      }
 $name=~s/ /_/g;
 $name=~s/"//g;
 $name=~s/:/_/g;
 $API{"Volume.Capacity_".$name}=$capacity; # in Byte
 $API{"Volume.Free_".$name}=$free; # in Byte
 }

if (defined($host_view->{runtime})) 
 {
 if ($host_view->{runtime}->{inMaintenanceMode}) 
   {
   $API{MaintenanceMode}=1; # in MaintenanceMode
   }else
	{
	$API{MaintenanceMode}=0; # not in MaintenanceMode
	}
 }

#Network Adapter
unless (defined($host_view->configManager->networkSystem)) {
   VIExt::fail("Error: network system not found.\n");
}
my $netsys = Vim::get_view (mo_ref => $host_view->configManager->networkSystem);
my $pnics = $netsys->networkInfo->pnic;
foreach my $pnic (@$pnics) 
{
      my ($state, $speed, $duplex);
      my $name="";
      my $ls = $pnic->linkSpeed;
      my $mtu_val = "";
      my $pci_device = find_pci_device($pnic->pci);

      if (defined($ls)) 
	{
         
	 $state = "1";
         $speed = $ls->speedMb * 1048576;
         $duplex = $ls->duplex ? "1" : "0";
       } else {
         $state = "0";
         $speed = "0";
         $duplex = "0";
      	      }

#      my $description = "";
#      eval {
#         $description = $pci_device->vendorName . " " . $pci_device->deviceName;
#           };
      $name=$pnic->device;
      $name=~s/ /_/g;
      $name=~s/"//g;
      $name=~s/:/_/g;
      $API{$name.".state"}=$state;    # Interface 1-UP 0-Down
      $API{$name.".speed"}=$speed;    # Speed bps
      $API{$name.".duplex"}=$duplex;  # 1- Full 0-Half

}
my $all_counters;
retrieve_performance(countertype=>"sys");
retrieve_performance(countertype=>"mem");
retrieve_performance(countertype=>"net");
retrieve_performance(countertype=>"disk");

foreach $i (keys %API)
 {
 $code=Write_Status(FILE=>$statusfile,NAME=>"$i",STATUS=>"$API{$i}");
 if ($code==1) {$error_code=2};
 }
print "$error_code\n";

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

sub find_pci_device 
{
   my ($pci_id) = @_;

   my $pci_devices = $host_view->hardware->pciDevice;
   foreach my $pci_dev (@$pci_devices) {
      if (defined($pci_dev->{id}) && $pci_dev->{id} eq $pci_id) {
         return $pci_dev;
      }
   }
}


sub retrieve_performance {
   my %args=(countertype=>"net",
          @_);
   my $host = Vim::find_entity_view(view_type => "HostSystem");
   if (!defined($host)) {
      Util::trace(0,"Host ".$IP." not found.\n");
      return;
   }
  
   my $perfmgr_view = Vim::get_view(mo_ref => Vim::get_service_content()->perfManager);
  
   my @perf_metric_ids = get_perf_metric_ids(perfmgr_view=>$perfmgr_view,
                                             host => $host,
                                             type => $args{countertype});

   my $perf_query_spec;
      my $intervals = get_available_intervals(perfmgr_view => $perfmgr_view,
                                              host => $host);
      $perf_query_spec = PerfQuerySpec->new(entity => $host,
                                            metricId => @perf_metric_ids,
#                                            'format' => 'csv',
					    'format' => 'normal',
                                            intervalId => shift @$intervals,
                                            maxSample => 1);

   my $perf_data;
   eval {
       $perf_data = $perfmgr_view->QueryPerf( querySpec => $perf_query_spec);
   };
   if ($@) {
      if (ref($@) eq 'SoapFault') {
         if (ref($@->detail) eq 'InvalidArgument') {
            Util::trace(0,"Specified parameters are not correct");
         }
      }
      return;
   }
   if (! @$perf_data) 
   {
      Util::trace(0,"Either Performance data not available for requested period "
                    ."or instance is invalid\n");
      $intervals = get_available_intervals(perfmgr_view=>$perfmgr_view,
                                           host => $host);
      Util::trace(0,"\nAvailable Intervals\n");
      foreach(@$intervals) 
      {
         Util::trace(0,"Interval " . $_ . "\n");
      }
      return;
   }
   foreach (@$perf_data) 
    {
#      print "Performance data for: " . $host->name . "\n";
#      my $time_stamps = $_->sampleInfoCSV;
      my $values = $_->value;
      foreach (@$values)
       {
#         print_counter_info($_->id->counterId, $_->id->instance);
#	 print "test ".$_->id->instance."\n";
#        print("Sample info : " . $time_stamps);
         my $test=$_->value;
         my @Value=@$test;
#         print("Value: " . $Value[0] . "\n");
         my $name=$_->id->counterId;
         my $counter = $all_counters->{$name};
         $name=$counter->nameInfo->label;
         if ($args{countertype} eq "mem") {$name=$counter->nameInfo->key}
	 if ($args{countertype} eq "net" || $args{countertype} eq "disk") {$name=$_->id ->instance}
         $name=~s/ /_/g;
         $name=~s/"//g;
         $name=~s/:/_/g;
         if ($args{countertype} eq "sys") 
	  {
	  $API{$name}=$Value[0];  # Uptime in sec
	  }
         if ($args{countertype} eq "mem")
          {
          $API{"MEM_".$name}=$Value[0] * 1024; # in Byte
          }
	 if ($args{countertype} eq "net")
          {
	  my $type=$counter->rollupType->val;
	  my $desc=$counter->nameInfo->label;
          my $units=$counter->unitInfo->label;
	  $desc=~s/ /_/g;
          $desc=~s/"//g;
          $desc=~s/:/_/g;
	  if ($name ne "" && $desc ne "" )
           {
	   if ($units eq "KBps")
	    {
	     if (lc($desc) eq "data_transmit_rate" ) {$desc="Network_Data_Transmit_Rate";}
	     if (lc($desc) eq "data_receive_rate" ) {$desc="Network_Data_Receive_Rate";}
            $API{$name.".".$desc.".".$type}=$Value[0] * 8192; # in bps
	    }else{
		 $API{$name.".".$desc.".".$type}=$Value[0]; # Number 
		 }
	   }
          }
	if ($args{countertype} eq "disk" && $name ne "")
          {
          my $type=$counter->rollupType->val;
          my $desc=$counter->nameInfo->label;
          my $units=$counter->unitInfo->label;
	  if (defined $ARRAY{$name}) 
	     {
	     $name=$ARRAY{$name};
	     }else{
	        my $i;
		my $max=-1;
		my $current=0;
		foreach $i (keys %ARRAY)
	         {
		 if ($ARRAY{$i}=~/Array_(\d+)/) {$current=$1; if ($current > $max) {$max=$current}}
		 }
		$max++;
		$ARRAY{$name}="Array_".$max;
		$name=$ARRAY{$name};	        
		}
          $desc=~s/ /_/g;
          $desc=~s/"//g;
          $desc=~s/:/_/g;
          if ($name ne "" && $desc ne "" )
           {
           if ($units eq "KBps")
            {
            $API{$name.".".$desc.".".$type}=$Value[0] * 1024; # in Bps
            }else{
                 $API{$name.".".$desc.".".$type}=$Value[0]; # Number or Millisecond
                 }
           }
          }

       }
   }
}

sub print_counter_info {
   my ($counter_id, $instance) = @_;
   my $counter = $all_counters->{$counter_id};
   print("Counter: " . $counter->nameInfo->label);
   if (defined $instance) {
      print("Instance : " . $instance);
   }
   print("Description: " . $counter->nameInfo->summary);
   print("Units: " . $counter->unitInfo->label);
}

sub get_perf_metric_ids {
   my %args = @_;
   my $perfmgr_view = $args{perfmgr_view};
   my $entity = $args{host};
   my $type = $args{type};

   my $counters;
   my @filtered_list;
   my $perfCounterInfo = $perfmgr_view->perfCounter;
   my $availmetricid = $perfmgr_view->QueryAvailablePerfMetric(entity => $entity);

   foreach (@$perfCounterInfo) {
      my $key = $_->key;
      $all_counters->{ $key } = $_;
      my $group_info = $_->groupInfo;
      if ($group_info->key eq $type) {
         $counters->{ $key } = $_;
      }
   }

   foreach (@$availmetricid) {
	 my $metric;
      if (exists $counters->{$_->counterId}) {
         #push @filtered_list, $_;
	 if ($type eq "disk" || $type eq "net")
	  {
          $metric = PerfMetricId->new (counterId => $_->counterId,
                                          instance => '*');
	  } else {
		 $metric = PerfMetricId->new (counterId => $_->counterId,
                                          instance => '');
		 }
         push @filtered_list, $metric;
      }
   }
   return \@filtered_list;
}

sub get_available_intervals {
   my %args = @_;
   my $perfmgr_view = $args{perfmgr_view};
   my $entity = $args{host};

   my $historical_intervals = $perfmgr_view->historicalInterval;
   my $provider_summary = $perfmgr_view->QueryPerfProviderSummary(entity => $entity);
   my @intervals;
   if ($provider_summary->refreshRate) {
      push @intervals, $provider_summary->refreshRate;
   }
   foreach (@$historical_intervals) {
      push @intervals, $_->samplingPeriod;
   }
   return \@intervals;
}
