#!/usr/bin/perl
#### Semi-automated Zabbix Proxy core functionality installer (for Commvault Log Monitoring V2 Proxy)
#### Version 2.7
#### Written by: Premysl Botek (premysl.botek@lab.com)
##################################################################################
#
#
#
## pragmas, global variable declarations, environment setup

use v5.10;
use strict;
use Cwd;
use Data::Dumper;
use Time::Piece;
use Time::Seconds;
use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);
use File::Copy qw(copy);
use File::Copy qw(move);
use File::Path qw(make_path);
use File::Basename;
use Sys::Hostname;
use FindBin '$Bin';
use LWP::UserAgent;

# DEPENDENT SETTINGS (values need to be reverified/set correctly during each installation - for this script to work and be integrated with the rest of functionality)

our $coreScriptsDestinationDir          = "/srv/zabbix/scripts/clmonitoring";
our $zabbixCrondConfigDir               = "/etc/cron.d";
our $zabbixWebsiteScriptsDestinationDir = "/var/www/html/clmonitoring";
our $zabbixCLMDataDir                   = "/clmdata";

our $installerTempDir  = cwd();
our $logFileName       = "$installerTempDir/log.txt";
#our $installerSpecFile = "$installerTempDir/installer.spec";

my $loggingLevel = 2
  ; # 0 - no logging, 1 - log errors only, 2 - log everything (errors, warnings, debug info)
my $logOutput = 2
  ; # 1 - output to console, 2 - output to log file, 3 - output to both console and log file

# End - DEPENDENT SETTINGS

my $thisModuleID =
  "INSTALLER";    # just for log file record identification purposes

my $installerLocksDir = "/srv/zabbix/scripts/installer-locks";
my $installerLockFile =
  $installerLocksDir . "/c3441e47-4572-4aad-9642-1a83a74f3c2f";

my $returnValue;

my $appMode = 1;    # 1 - install, 2 - uninstall

my $specFileRequiredRPMPackages;
my $specFileRequiredPerlModules;

my $encounteredErrors = 0;

my $invalidCommandLine = 0;

# self reflection

hostname =~ /^(.*?)\..*/
  ; # get system hostname and clean out possible domain (clean everything after first dot, inclusive)
my $thisMachineHostname = $1;

my ( $tmpName, $tmpPath, $tmpSuffix ) = fileparse( $0, qr{\.[^.]*$} );
my $thisScriptFileName = $Bin . '/' . $tmpName . $tmpSuffix;

## program entry point ###########################################################################

main();

print $encounteredErrors;
exit $encounteredErrors;

##  program exit point	###########################################################################

sub fnExecuteInstallAction {
	my $subResult = 0;
	my $tmpFileName;
#	if ( !-f $installerSpecFile ) {
#		logEvent( 2, "Can not open installer spec file $installerSpecFile" );
#		return $subResult;
#
#	}
#	loadInstallerSpecFile();
#	if ( $encounteredErrors > 0 ) {
#		return $subResult;
#	}
### - check required RPM packages
	#
	#	installerCheckInstalledRPMPackages();
	#	if ( $encounteredErrors > 0 ) {
	#		return $subResult;
	#	}
	#
### - check required Perl modules
	#
	#	installerCheckInstalledPerlModules();
	#	if ( $encounteredErrors > 0 ) {
	#		return $subResult;
	#	}

## - install CPAN modules

#	installerCheckInternetConnection1( 'http://www.google.com', 5 );		# www.perl.org can not be used because it has permanent redirect to https site that can not be communicated to without adding more CPAN SSL modules
#	if ( $encounteredErrors > 0 ) {
#		return $subResult;
#	}

#	my $cpanCommonModules1 =
#'Config::Simple Data::Dumper Net::OpenSSH Time::Piece Time::HiRes DBI DBD::SQLite Date::Parse Date::Format';

#	my $cpanExtraModules1 = ' Text::CSV';

#	my ( $execSubResult, $execResultCode, $execStdErr, @execOutput ) =
#	  installerExecuteShellCommand(
#		'yes | cpan -i ' . $cpanCommonModules1 . $cpanExtraModules1 );
#	if ( $encounteredErrors > 0 ) {
#		return $subResult;
#	}

## - create core scripts directory
	installerMakePath( 1, $coreScriptsDestinationDir, 0 );
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

## install monitoring script

	$tmpFileName = 'diag-n-maintain.pl';

	installerCopyFile(
		1,
		$installerTempDir . '/' . $tmpFileName,
		$coreScriptsDestinationDir . '/' . $tmpFileName
	);
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

## install monitoring script

	$tmpFileName = 'scheduler.pl';

	installerCopyFile(
		1,
		$installerTempDir . '/' . $tmpFileName,
		$coreScriptsDestinationDir . '/' . $tmpFileName
	);
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

## install monitoring script

	$tmpFileName = 'harvest-logs.pl';

	installerCopyFile(
		1,
		$installerTempDir . '/' . $tmpFileName,
		$coreScriptsDestinationDir . '/' . $tmpFileName
	);
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

## install monitoring script

	$tmpFileName = 'analyze-data.pl';

	installerCopyFile(
		1,
		$installerTempDir . '/' . $tmpFileName,
		$coreScriptsDestinationDir . '/' . $tmpFileName
	);
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

## install monitoring script

	$tmpFileName = 'get-data.pl';

	installerCopyFile(
		1,
		$installerTempDir . '/' . $tmpFileName,
		$coreScriptsDestinationDir . '/' . $tmpFileName
	);
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

## install binary

	$tmpFileName = 'vmtouch';

	installerCopyFile(
		1,
		$installerTempDir . '/' . $tmpFileName,
		$coreScriptsDestinationDir . '/' . $tmpFileName
	);
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

## install binary

	$tmpFileName = 'linux-fincore';

	installerCopyFile(
		1,
		$installerTempDir . '/' . $tmpFileName,
		$coreScriptsDestinationDir . '/' . $tmpFileName
	);
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

## install cron config file

	$tmpFileName = 'monitoring-commvault';

	installerCopyFile(
		1,
		$installerTempDir . '/' . $tmpFileName,
		$zabbixCrondConfigDir . '/' . $tmpFileName
	);
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

## - install website scripts
	installerMakePath( 1, $zabbixWebsiteScriptsDestinationDir, 0 );
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

	$tmpFileName = 'zscrdetail1.php';

	installerCopyFile(
		1,
		$installerTempDir . '/' . $tmpFileName,
		$zabbixWebsiteScriptsDestinationDir . '/' . $tmpFileName
	);
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

### copy file installer.spec - just for future debugging and reference reason
#
#	$tmpFileName = 'installer.spec';
#
#	installerCopyFile(
#		1,
#		$installerTempDir . '/' . $tmpFileName,
#		$coreScriptsDestinationDir . '/' . $tmpFileName
#	);
#	if ( $encounteredErrors > 0 ) {
#		return $subResult;
#	}

## - create Commvault Monitoring data directory structure

	installerMakePath( 1, $zabbixCLMDataDir, 0 );
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

	installerMakePath( 1, $zabbixCLMDataDir . '/bkp', 0 );
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

	installerMakePath( 1, $zabbixCLMDataDir . '/bkp/manualupload', 0 );
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

	installerMakePath( 1, $zabbixCLMDataDir . '/database', 0 );
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

	installerMakePath( 1, $zabbixCLMDataDir . '/reportsretention', 0 );
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

	installerMakePath( 1, $zabbixCLMDataDir . '/scriptslog', 0 );
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

## - set access permissions to all script files (here to be able to execute script files below)

	my ( $execSubResult, $execResultCode, $execStdErr, @execOutput ) =
	  installerExecuteShellCommand(
		'chmod 774 ' . $coreScriptsDestinationDir . '/*' );
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

## - create core scripts database set

	#  create
	my ( $execSubResult, $execResultCode, $execStdErr, @execOutput ) =
	  installerExecuteShellCommand( $coreScriptsDestinationDir
		  . '/diag-n-maintain.pl maintain createnewdatabase' );
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

	# configure database-stored variables

	my ( $execSubResult, $execResultCode, $execStdErr, @execOutput ) =
	  installerExecuteShellCommand( $coreScriptsDestinationDir
		  . '/diag-n-maintain.pl SETTING SET WEB_APP_URL http://'
		  . $thisMachineHostname
		  . '/clmonitoring/' );
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

## - set ownership to the script directory

	my ( $execSubResult, $execResultCode, $execStdErr, @execOutput ) =
	  installerExecuteShellCommand(
		'chown -R zabbix:zabbix ' . $coreScriptsDestinationDir );
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

## - set permissions to the script directory

	my ( $execSubResult, $execResultCode, $execStdErr, @execOutput ) =
	  installerExecuteShellCommand(
		'chmod -R 775 ' . $coreScriptsDestinationDir );
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

## - set all permissions to files in the script directory

	# - default permissions to all files

	my ( $execSubResult, $execResultCode, $execStdErr, @execOutput ) =
	  installerExecuteShellCommand(
		'chmod -R 664 ' . $coreScriptsDestinationDir . "/*" );
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

	# - permissions to executable files

	my ( $execSubResult, $execResultCode, $execStdErr, @execOutput ) =
	  installerExecuteShellCommand(
		'chmod 774 ' . $coreScriptsDestinationDir . "/*.pl" );
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

	my ( $execSubResult, $execResultCode, $execStdErr, @execOutput ) =
	  installerExecuteShellCommand(
		'chmod 774 ' . $coreScriptsDestinationDir . "/vmtouch" );
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

	my ( $execSubResult, $execResultCode, $execStdErr, @execOutput ) =
	  installerExecuteShellCommand(
		'chmod 774 ' . $coreScriptsDestinationDir . "/linux-fincore" );
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

## modifications of permissions and ownership commvault monitoring data directory (/clmdata) etc.

	# set ownership

	my ( $execSubResult, $execResultCode, $execStdErr, @execOutput ) =
	  installerExecuteShellCommand(
		'chown -R zabbix:zabbix ' . $zabbixCLMDataDir );
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

	# set access permissions
	my ( $execSubResult, $execResultCode, $execStdErr, @execOutput ) =
	  installerExecuteShellCommand( 'chmod -R 775 ' . $zabbixCLMDataDir );
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

## add user 'apache' to 'zabbix' group so Apache can write to the core scripts database and restart httpd to apply changes
	my ( $execSubResult, $execResultCode, $execStdErr, @execOutput ) =
	  installerExecuteShellCommand('usermod -G zabbix apache');
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

	my ( $execSubResult, $execResultCode, $execStdErr, @execOutput ) =
	  installerExecuteShellCommand('service httpd restart');
	if ( $encounteredErrors > 0 ) {
		return $subResult;
	}

##
	$subResult = 1;
	return $subResult;
}

sub main {
	my $subResult = 0;
## program initialization

	my $commandline = join " ", $0, @ARGV;
	logEvent( 1, "Used command line: $commandline" );

	if ( scalar(@ARGV) > 0 ) {
		$invalidCommandLine = 1;

		given ( uc( $ARGV[0] ) ) {

			when ("UNINSTALL") {

				$appMode            = 2;
				$invalidCommandLine = 0;

				#logEvent( 1, "t2 " );

			}

		}
	}

	if ($invalidCommandLine) {

		my $commandline = join " ", $0, @ARGV;
		logEvent( 2, "Invalid command line: $commandline" );

		print <<USAGELABEL;
Invalid command line parameters
	
USAGE:		perl installer.pl
	
LOGGING:			set \$loggingLevel variable : 0 - no logging, 1 - log errors only, 2 - log everything (errors, warnings, debug info)

				set \$logOutput variable : 1 - output to console, 2 - output to log file, 3 - output to both console and log file

USAGELABEL

		$encounteredErrors++;
		return $subResult;
	}

#### main execution block

	if ( -f $installerLockFile ) {
		logEvent( 2,
"Previous installation detected (lock file $installerLockFile exists). Quitting."
		);

		$subResult = 1;
		return $subResult;
	}

##

	given ($appMode) {

		when (1) {

			fnExecuteInstallAction();
			if ( $encounteredErrors > 0 ) {
				return $subResult;
			}

		}

		# NOT TO BE IMPLEMENTED
		#	when (2) {
		#		print fnExecuteUnInstallAction();
		#
		#	}

	}

## end - main execution block

## create installer lock file

	installerMakePath( 1, $installerLocksDir, 1 );
	$encounteredErrors = 0;

	installerTouchFile( 1, $installerLockFile,
"This is an Installation Lock File, preventing multiple successfull installer runs. Associated installer: "
		  . $thisScriptFileName );

##

	logEvent( 1, "Installation successfully completed." );

	$subResult = 1;
	return $subResult;

}

################# - Installer API Library ver. seq. #12

#sub loadInstallerSpecFile {
#	my $subResult = 0;
#
#	#
#	#	read_config $installerSpecFile => my %cfg;
#	#
####
##
##	$specFileRequiredRPMPackages =
##	  $cfg{"PRE_INSTALL_REQUIREMENTS"}{"RPM_REQUIRED_PACKAGE"};
##
##	if ( !defined($specFileRequiredRPMPackages) ) {
##		logEvent( 2,
##"Error 1 in loadInstallerSpecFile(). Parameter [PRE_INSTALL_REQUIREMENTS]/RPM_REQUIRED_PACKAGE does not exist in $installerSpecFile"
##		);
##		$encounteredErrors++;
##		return $subResult;
##
##	}
##
####
##
##	$specFileRequiredPerlModules =
##	  $cfg{"PRE_INSTALL_REQUIREMENTS"}{"PERL_REQUIRED_MODULE"};
##
##	if ( !defined($specFileRequiredPerlModules) ) {
##		logEvent( 2,
##"Error 1 in loadInstallerSpecFile(). Parameter [PRE_INSTALL_REQUIREMENTS]/PERL_REQUIRED_MODULE does not exist in $installerSpecFile"
##		);
##		$encounteredErrors++;
##		return $subResult;
##
##	}
##
#####
#	#	#print Dumper($clustername);
#
#	logEvent( 1, "Successfully loaded specs from $installerSpecFile" );
#
#	$subResult = 1;
#	return $subResult;
#
#}

# method Version: 2
sub installerMakePath {
	my ( $actionMode, $pathName, $doNotThrowErrors ) =
	  @_;    # $actionMode: 1 - install, 2 - uninstall

	my $subResult = 0;

	if ( $actionMode == 1 ) {

		if ( !make_path($pathName) ) {

			if ( $doNotThrowErrors == 1 ) {
				logEvent( 1, "Can not make path $pathName: $!" );

			}
			else {
				logEvent( 2,
"Error 1 in installerMakePath(). Can not make path $pathName: $!"
				);
				$encounteredErrors++;

			}

			return $subResult;
		}

	}
	else {

		# stub - delete path goes here

	}

	logEvent( 1, "Successfully created path $pathName" );

	$subResult = 1;

	return $subResult;

}

sub installerFileChmod {
	my ( $fileName, $fileMode ) = @_;

	my $subResult = 0;

	if ( !chmod( $fileMode, $fileName ) ) {
		logEvent( 2,
"Error 1 in installerFileChmod(). Can not set permissions $fileMode to $fileName: $!"
		);
		$encounteredErrors++;
		return $subResult;
	}

	logEvent( 1, "Successfully set permissions $fileMode to $fileName" );

	$subResult = 1;

	return $subResult;

}

sub installerCopyFile {
	my ( $actionMode, $sourceFilePath, $destinationFilePath ) =
	  @_;    # $actionMode: 1 - install, 2 - uninstall

	my $subResult = 0;

	if ( $actionMode == 1 ) {

		if ( !copy( $sourceFilePath, $destinationFilePath ) ) {
			logEvent( 2,
"Error 1 in installerCopyFile(): Could not copy file $sourceFilePath to $destinationFilePath: : $!"
			);
			$encounteredErrors++;
			return $subResult;

		}

	}
	else {

		# stub - delete file goes here

	}

	logEvent( 1,
		"Successfully copied file $sourceFilePath to $destinationFilePath" );

	$subResult = 1;

	return $subResult;

}

sub installerModifyTextFile {
	my ( $modificationMode, $fileName, $correctFunctionReplacementsCount,
		$param1, $param2 )
	  = @_;

# $modificationMode: 1 - (usage: variables modifications in Perl sources) Replaces line detected by Regex pattern in $param1 with line from $param2
# $modificationMode: 2 - (usage: adding new lines in Zabbix config files ) Inserts string from $param2 at the begin of the specified config section (section header is detected by $param1 - not Regex but a simple match)

	my $replacementCounter = 0;
	my $input              = $fileName;
	my $output             = $fileName . "_tmp";
	my $modificationModeHeadMode =
	  0;    # 0 - unknown, 1 - scanning, 2 inside section header, 3 - finished
	my $subResult = 0;

	if ( !open( INPUT, $input ) ) {

		logEvent( 2,
"Error 1 in installerModifyTextFile(). Can not open input file $input: $!"
		);
		$encounteredErrors++;
		return $subResult;
	}

	if ( !open( OUTPUT, '>' . $output ) ) {
		logEvent( 2,
"Error 2 in installerModifyTextFile(). Can not create output file $output: $!"
		);
		$encounteredErrors++;
		return $subResult;
	}

	## specific functionality for $modificationMode=1
	if ( $modificationMode == 1 ) {

		# Read the input file one line at a time.
		while ( my $line = <INPUT> ) {

			if ( $line =~ /$param1/ ) {
				$line = $param2;
				$replacementCounter++;

			}
			print OUTPUT $line;
		}

	}

	## specific functionality for $modificationMode=2
	if ( $modificationMode == 2 ) {

		$modificationModeHeadMode = 1;

		# Read the input file one line at a time.
		while ( my $line = <INPUT> ) {

			if ( $line eq $param1 ) {
				$modificationModeHeadMode =
				  2;    # found start of the specified header
			}

			if ( ( $modificationModeHeadMode == 2 ) && !( $line =~ /^\#/ ) ) {
				$modificationModeHeadMode = 3
				  ; # found end of the specified header (after first line of header, skipped all lines that start with #)

				print OUTPUT $param2;

				$replacementCounter++;

			}

			print OUTPUT $line;
		}

	}

	close(INPUT);
	close(OUTPUT);

	if ( $correctFunctionReplacementsCount != $replacementCounter ) {

		logEvent( 2,
"Error 3 in installerModifyTextFile() while processing $fileName: Found $replacementCounter lines matching replacement pattern $param1 while should find $correctFunctionReplacementsCount."
		);
		$encounteredErrors++;
		return $subResult;

	}
	else {

		if ( !unlink($input) ) {
			logEvent( 2,
"Error 4 in installerModifyTextFile(): Can not delete file $input: $!"
			);
			$encounteredErrors++;
			return $subResult;

		}

		if ( !move( $output, $input ) ) {
			logEvent( 2,
"Error 5 in installerModifyTextFile(): Can not rename file $output to $input: $!"
			);
			$encounteredErrors++;
			return $subResult;

		}

	}

	logEvent( 1,
"Successfully modified file $input (replaced '$param1' with '$param2' $replacementCounter times)"
	);

	$subResult = 1;

	return $subResult;

}

sub installerTouchFile {
	my ( $actionMode, $fileName, $content ) =
	  @_;    # $actionMode: 1 - install, 2 - uninstall

	my $subResult = 0;

	if ( $actionMode == 1 ) {

		logEvent( 1, "Creating new file $fileName. Content: $content" );

		if ( !open( OUTPUT, '>' . $fileName ) ) {
			logEvent( 2,
"Error 1 in installerTouchFile(). Can not create file $fileName: $!"
			);
			$encounteredErrors++;
			return $subResult;
		}

		print OUTPUT $content;

		close(OUTPUT);

	}
	else {

		# stub - delete path goes here

	}

	$subResult = 1;

	return $subResult;

}

sub checkPerlModule {
	my ($moduleSpecs) = @_;
	my $moduleName;

	my @moduleSpecsArray = split( /\s*,\s*/, $moduleSpecs );
	$moduleName = @moduleSpecsArray[0];

	eval("use $moduleName");

	if ($@) {
		return (0);
	}
	else {
		return (1);
	}
}

sub installerCheckInstalledPerlModules {
	my $localEncounteredErrors = 0;
	my $subResult              = 1;

	foreach (@$specFileRequiredPerlModules) {

		if ( checkPerlModule($_) == 0 ) {

			$subResult = 0;
			$encounteredErrors++;
			$localEncounteredErrors++;

			logEvent( 2, "Perl module $_ is not installed" );

		}
	}

	logEvent( 1,
"Completed installerCheckInstalledPerlModules(), encountered $localEncounteredErrors errors"
	);

	return $subResult;

}

sub checkRPMPackage {
	my ($packageSpecs) = @_;
	my $RPMDatabase;
	my $RPMPackage;
	my $packageName;
	my $packagesIterList;

	my $subResult = 0;

	$RPMDatabase = RPM2->open_rpm_db();

	my @packageSpecsArray = split( /\s*,\s*/, $packageSpecs );
	$packageName = @packageSpecsArray[0];

	$packagesIterList = $RPMDatabase->find_by_name_iter($packageName);

	$RPMPackage = $packagesIterList->next;

	if ( defined($RPMPackage) ) {
		$subResult = 1;
	}

	$RPMDatabase = undef;

	return $subResult;
}

sub installerCheckInstalledRPMPackages {
	my $localEncounteredErrors = 0;
	my $subResult              = 1;
	foreach (@$specFileRequiredRPMPackages) {

		if ( checkRPMPackage($_) == 0 ) {

			$subResult = 0;
			$encounteredErrors++;
			$localEncounteredErrors++;

			logEvent( 2, "RPM package $_ is not installed" );

		}
	}

	logEvent( 1,
"Completed installerCheckInstalledRPMPackages(), encountered $localEncounteredErrors errors"
	);

	return $subResult;

}

sub installerExecuteShellCommand() {
	my ($cmd1) = @_;
	my $returnSubResult = 0;
	my $execStdErrBackup;
	my $execStdErr;
	my @execOutput;
	my $execResultCode;

	logEvent( 1, "Executing $cmd1" );

	# backup STDERR, to be restored later
	open( $execStdErrBackup, ">&", \*STDERR ) or do {

		logEvent( 2,
			"Error 1 in installerExecuteShellCommand(): Can't backup STDERR: $!"
		);
		$encounteredErrors++;
		return $returnSubResult;
	};

	# close first (according to the perldocs)
	close(STDERR) or return $returnSubResult;

	# redirect STDERR to in-memory scalar

	open( STDERR, '>', \$execStdErr ) or do {
		logEvent( 2,
"Error 2 in installerExecuteShellCommand(): Can't redirect STDERR: $!"
		);
		$encounteredErrors++;
		return $returnSubResult;
	};

	@execOutput = `$cmd1`;    # execute shell command

	$execResultCode = $? >> 8;

	#$tmpStr1    = @$execStdErr[0];

	# restore original STDERR
	open( STDERR, ">&", $execStdErrBackup ) or do {
		logEvent( 2,
"Error 3 in installerExecuteShellCommand(): Can't restore STDERR: $!"
		);
		$encounteredErrors++;
		return $returnSubResult;
	};

	logEvent( 1, "Execution result code: $execResultCode" );
	logEvent( 1, "Execution output:" . Dumper(@execOutput) );
	logEvent( 1, "STDERR output: $execStdErr" );

	if ( $execResultCode ne "0" ) {
		logEvent( 2,
"Error 4 in installerExecuteShellCommand(): execResultCode is $execResultCode"
		);
		$encounteredErrors++;
		return $returnSubResult;

	}
	else {

		$returnSubResult = 1;

	}

	return ( $returnSubResult, $execResultCode, $execStdErr, \@execOutput );

}

# checks connection to a www server
sub installerCheckInternetConnection1 {
	my ( $serverURL, $requestTimeout ) = @_;
	my $subResult = 0;

	my $ua = LWP::UserAgent->new;
	$ua->timeout($requestTimeout);
	$ua->env_proxy;

	my $response = $ua->get($serverURL);

	if ( $response->is_success ) {
		$subResult = 1;
	}
	else {

		logEvent( 2,
			"Error 1 in installerCheckInternetConnection1(): "
			  . $response->status_line );
		$encounteredErrors++;

	}

	return $subResult;
}

################# EOF - Installer API Library

sub logEvent {    # method Version: 3
	my ( $eventType, $msg ) =
	  @_;         # event type: 1 - debug info, 2 - error, 3 - warning

	my ( $s, $usec ) = gettimeofday();    # get microseconds haha
	my $timestamp = localtime->strftime("%Y-%m-%d %H:%M:%S.") . ($usec);

	my $eventTypeDisplay = "";

	if ( ( $loggingLevel == 0 ) || ( $logOutput == 0 ) ) {
		return 0;
	}

	given ($eventType) {
		when (1) {
			$eventTypeDisplay = " Debug Info : ";

			if ( $loggingLevel == 1 ) {
				return 0;
			}

		}

		when (2) {
			$eventTypeDisplay = " !ERROR! : ";
		}

		when (3) {
			$eventTypeDisplay = " Warning : ";

			if ( $loggingLevel == 1 ) {
				return 0;
			}

		}

	}

	if ( ( $logOutput == 1 ) || ( $logOutput == 3 ) ) {

		print "[$$] $timestamp$eventTypeDisplay$msg\n";

	}

	if ( ( $logOutput == 2 ) || ( $logOutput == 3 ) ) {

		if ( open( LOGFILEHANDLE, ">>$logFileName" ) ) {
			print LOGFILEHANDLE
			  "[$thisModuleID][$$] $timestamp$eventTypeDisplay$msg\n";
			close LOGFILEHANDLE;

		}
		else {

			print "Can not open logfile $logFileName : $!\n";

		}

	}

}
