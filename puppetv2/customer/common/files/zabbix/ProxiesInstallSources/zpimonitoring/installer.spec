############################################################################################################
[GENERAL]

CLASS = zpim_proxy_generic
DESCRIPTION = Zabbix Proxy Internal Monitoring - Zabbix Proxy Generic Installer (as per https://wiki.lab.com.au/display/ENG/Zabbix+Proxy+Performance+Monitoring+and+Tuning)



############################################################################################################
## Note: entities listed in [PRE_INSTALL_REQUIREMENTS] are to be managed by Puppet only (please do not manage them on this machine manually)
[PRE_INSTALL_REQUIREMENTS]

# Machine and system requirements
# none


# List of required /etc/passwd modifications to be done by Puppet
SYSTEM_PASSWD_CONFIG_ENTRY = zabbix, /bin/bash


# List of required zabbix_agentd.conf modifications to be done by Puppet (please copy with comments for easier future debugging)
ZABBIX_AGENT_CONFIG_ENTRY = UserParameter=PMCU[*],/etc/zabbix/zproxyinternalmonitoringcommonutils.pl $1 $2 $3 $4 $5 $6 $7 $8 $9   # Zabbix Proxy Internal Monitoring


# RPM_REQUIRED_PACKAGE list item format: RPM_REQUIRED_PACKAGE = <moduleName>[,minimumSupportedVersion][,maximumSupportedVersion]
RPM_REQUIRED_PACKAGE = perl, 5.10
RPM_REQUIRED_PACKAGE = zabbix-agent, 1.8
RPM_REQUIRED_PACKAGE = zabbix-proxy-sqlite3, 1.8
RPM_REQUIRED_PACKAGE = fping
RPM_REQUIRED_PACKAGE = make
RPM_REQUIRED_PACKAGE = gcc
RPM_REQUIRED_PACKAGE = perl-CPAN


# PERL_REQUIRED_MODULE list item format: PERL_REQUIRED_MODULE = <moduleName>[,minimumSupportedVersion][,maximumSupportedVersion]
PERL_REQUIRED_MODULE = Cwd
PERL_REQUIRED_MODULE = Data::Dumper
PERL_REQUIRED_MODULE = Time::Piece
PERL_REQUIRED_MODULE = Time::Seconds
PERL_REQUIRED_MODULE = Time::HiRes
PERL_REQUIRED_MODULE = Config::Std
PERL_REQUIRED_MODULE = Config::Simple
PERL_REQUIRED_MODULE = File::Copy
PERL_REQUIRED_MODULE = File::Path


INSTALLATION_SOURCE_FILES_GIT_REPO_DIR = https://git.harbour/monitoring/zabbixproxyinternalmonitoringv1/tree/master/Deployment



############################################################################################################
## Note: entities listed in [INSTALLATION] are set up at machine deployment time by the installer.pl. Puppet does not manage them and you can manage them on this machine manually
[INSTALLATION]

CORE_SCRIPTS_DESTINATION_DIR = /srv/zabbix/scripts/zpimonitoring



############################################################################################################
## Note: entities listed in [POST_INSTALL_REQUIREMENTS] are not managed by Puppet and you can manage them on this machine manually
[POST_INSTALL_REQUIREMENTS]

MANUAL_PROCEDURE = As per steps in chapter 25.3.2 and 25.3.3 at https://wiki.lab.com.au/display/ENG/Zabbix+%281.8+and+2.2%29+Dev+Environment+Build+Guide#Zabbix(1.8and2.2)DevEnvironmentBuildGuide-25.3.2Zabbixhostconfiguration


