############################################################################################################
[GENERAL]

CLASS = esxi_proxy_generic
DESCRIPTION = Zabbix ESXi Monitoring V1 Proxy Generic Installer (partially documented at https://wiki.lab.com.au/pages/viewpage.action?pageId=2657541)



############################################################################################################
## Note: entities listed in [PRE_INSTALL_REQUIREMENTS] are to be managed by Puppet only (please do not manage them on this machine manually)
[PRE_INSTALL_REQUIREMENTS]

# Machine and system requirements
SYSTEM_CPU_COUNT = 2
SYSTEM_RAM_GB = 2
SYSTEM_SWAP_GB = 2


# DISK_VOLUME list item format: DISK_VOLUME = <order number starting from 0>, <size in GB>, [filesystem type]
DISK_VOLUME = 0, 12, ext4


## RPM_REQUIRED_PACKAGE list. Item format: RPM_REQUIRED_PACKAGE = <moduleName>[,minimumSupportedVersion][,maximumSupportedVersion]
# Required by Installer:
RPM_REQUIRED_PACKAGE = perl, 5.10
# Required by Proxy Scripts:
RPM_REQUIRED_PACKAGE = perl, 5.10
RPM_REQUIRED_PACKAGE = zabbix-agent, 1.8
RPM_REQUIRED_PACKAGE = zabbix-proxy-sqlite3, 1.8
RPM_REQUIRED_PACKAGE = iksemel
RPM_REQUIRED_PACKAGE = OpenIPMI-libs
RPM_REQUIRED_PACKAGE = fping


# PERL_REQUIRED_MODULE list item format: PERL_REQUIRED_MODULE = <moduleName>[,minimumSupportedVersion][,maximumSupportedVersion]
# Required by Installer:
PERL_REQUIRED_MODULE = Cwd
PERL_REQUIRED_MODULE = Data::Dumper
PERL_REQUIRED_MODULE = Time::Piece
PERL_REQUIRED_MODULE = Time::Seconds
PERL_REQUIRED_MODULE = Time::HiRes
PERL_REQUIRED_MODULE = Config::Simple
PERL_REQUIRED_MODULE = File::Copy
PERL_REQUIRED_MODULE = File::Path
# Required by Proxy Scripts:
# none


# Relevant Puppet class that deploys this Zabbix Proxy VM and runs installer.pl
PUPPET_CLASS_GIT_DIR = "/customer/common/manifests/zabbix/esxi_proxy_generic.pp"



############################################################################################################
## Note: entities listed in [INSTALLATION] are set up at machine deployment time by the installer.pl. Puppet does not manage them and you can manage them on this machine manually
[INSTALLATION]


# as per sub fnExecuteInstallAction in installer.pl



############################################################################################################
## Note: entities listed in [POST_INSTALL_REQUIREMENTS] are not managed by Puppet and you can manage them on this machine manually
[POST_INSTALL_REQUIREMENTS]

# 1) Register proxy in Zabbix
# 2) Add new ESXi hypervisors to monitoring as per documentation


