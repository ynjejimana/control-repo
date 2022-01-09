class common::clamav::agent::params { 

### Specific to OS and Major version variables

  case $::osfamily {
    'RedHat': {
      case $::operatingsystemmajrelease {
        '6': {
          $pkgs                         = [ 'clamav' ]
          $svcs_daemon                  = [ 'clamd' ]
          $freshclamUser                = 'clam'
          $fresclamGroup                = 'clam'

          $clamdConfFile                = '/etc/clamd.conf'

          $files2remove                 = [ '/etc/cron.daily/freshclam' ]

        }
        '7': {

          $pkgs                         = [ 'clamav', 'clamav-update' ]
          $svcs_daemon                  = [ 'clamd@scan' ]
          $freshclamUser                = 'clamupdate'
          $fresclamGroup                = 'clamupdate'

          $clamdConfFile                = '/etc/clamd.d/scan.conf'

          $files2remove                 = [ '/etc/cron.d/clamav-update' ]

        }
      }

      $pkgs_daemon                      = [ 'clamd' ]

    }
    default: {
      fail("${::operatingsystem} is not supported.")
    }
  }

### General parameters

  $clamScanEnabled                  = true
  $clamDaemonEnabled                = false
  $clamDatabaseDirectory            = '/var/lib/clamav'

  $clamSELinuxConfig               = [ 'antivirus_can_scan_system', 'antivirus_use_jit' ]


### ClamAV updater parameters

  $freshclamUpdateLogFile           = '/var/log/freshclam.log'
  $freshclamLogFileMaxSize          = '5M'
  $freshclamLogTime                 = 'yes'
  $freshclamLogVerbose              = undef
  $freshclamLogSyslog               = 'yes'
  $freshclamLogFacility             = undef
  $freshclamPidFile                 = undef
  $freshclamDatabaseOwner           = $freshclamUser
  $freshclamPrivateMirrorList       = []
  $freshclamDNSDatabaseInfo         = 'current.cvd.clamav.net'
  $freshclamDatabaseMirror          = 'database.clamav.net'
  $freshclamScriptedUpdates         = 'no'
  $freshclamDatabaseCustomURLList   = []
  $freshclamExtraDatabaseList       = []
  $freshclamHTTPProxyServer         = undef
  $freshclamHTTPProxyPort           = undef
  $freshclamHTTPProxyUsername       = undef
  $freshclamHTTPProxyPassword       = undef
  $freshclamMaxAttempts             = 3
  $freshclamCompressLocalDatabase   = 'no'
  $freshclamChecks                  = 2
  $freshclamHTTPUserAgent           = undef
  $freshclamNotifyClamd             = undef
  $freshclamOnUpdateExecute         = undef
  $freshclamOnErrorExecute          = undef
  $freshclamOnOutdatedExecute       = undef
  $freshclamForeground              = 'no'
  $freshclamDebug                   = 'no'
  $freshclamConnectTimeout          = 30
  $freshclamReceiveTimeout          = 30
  $freshclamTestDatabases           = 'yes'
  $freshclamSafeBrowsing            = 'no'
  $freshclamBytecode                = 'yes'

### ClamAV scan parameters

  $scanMoveDir                      = undef
  $scanClamScanLogFile              = '/var/log/clamscan.log'
  $scanLogFile                      = '/var/log/clamd.log'
  $scanLogFileUnlock                = undef
  $scanLogFileMaxSize               = '5M'
  $scanLogTime                      = 'yes'
  $scanLogClean                     = 'no'
  $scanLogFacility                  = undef
  $scanLogVerbose                   = undef
  $scanPreludeEnable                = undef
  $scanPreludeAnalyzerName          = undef
  $scanExtendedDetectionInfo        = 'yes'
  $scanPidFile                      = undef
  $scanTemporaryDirectory           = undef
  $scanOfficialDatabaseOnly         = undef

  $scanLocalSocket                  = '/var/run/clamd.scan/clamd.sock'
  $scanLocalSocketGroup             = undef
  $scanLocalSocketMode              = undef
  $scanFixStaleSocket               = undef

  $scanTCPSocket                    = undef
  $scanTCPAddr                      = undef

  $scanMaxConnectionQueueLength     = undef
  $scanStreamMaxLength              = undef
  $scanStreamMinPort                = undef
  $scanMaxThreads                   = undef
  $scanReadTimeout                  = undef
  $scanCommandReadTimeout           = undef
  $scanSendBufTimeout               = undef
  $scanMaxQueue                     = undef
  $scanIdleTimeout                  = undef
  $scanExcludePathList              = []
  $scanExcludeFileList              = []
  $scanMaxDirectoryRecursion        = undef
  $scanFollowDirectorySymlinks      = undef
  $scanFollowFileSymlinks           = undef
  $scanCrossFilesystems             = 'yes'
  $scanSelfCheck                    = undef
  $scanVirusEvent                   = undef
  $scanExitOnOOM                    = undef
  $scanForeground                   = undef
  $scanDebug                        = undef
  $scanLeaveTemporaryFiles          = undef
  $scanAllowAllMatchScan            = undef
  $scanDetectPUA                    = undef
  $scanExcludePUAList               = []
  $scanIncludePUAList               = []
  $scanForceToDisk                  = undef
  $scanDisableCache                 = undef
  $scanHeuristicAlerts              = undef
  $scanHeuristicScanPrecedence      = undef
  $scanAlertBrokenExecutables       = undef
  $scanAlertEncrypted               = undef
  $scanAlertEncryptedArchive        = undef
  $scanAlertEncryptedDoc            = undef
  $scanAlertOLE2Macros              = undef
  $scanAlertPhishingSSLMismatch     = undef
  $scanAlertPhishingCloak           = undef
  $scanAlertPartitionIntersection   = undef
  $scanScanPE                       = undef
  $scanDisableCertCheck             = undef
  $scanScanELF                      = undef
  $scanScanOLE2                     = undef
  $scanScanPDF                      = undef
  $scanScanSWF                      = undef
  $scanScanXMLDOCS                  = undef
  $scanScanHWP3                     = undef
  $scanScanMail                     = undef
  $scanScanPartialMessages          = undef

  $scanPhishingSignatures           = undef
  $scanPhishingScanURLs             = undef
  $scanStructuredDataDetection      = undef
  $scanStructuredMinCreditCardCount = undef
  $scanStructuredMinSSNCount        = undef
  $scanStructuredSSNFormatNormal    = undef
  $scanStructuredSSNFormatStripped  = undef
  $scanScanHTML                     = undef
  $scanScanArchive                  = undef
  $scanMaxScanTime                  = undef
  $scanMaxScanSize                  = undef
  $scanMaxFileSize                  = undef
  $scanMaxRecursion                 = undef
  $scanMaxFiles                     = undef
  $scanMaxEmbeddedPE                = undef
  $scanMaxHTMLNormalize             = undef
  $scanMaxHTMLNoTags                = undef
  $scanMaxScriptNormalize           = undef
  $scanMaxZipTypeRcg                = undef
  $scanMaxPartitions                = undef
  $scanMaxIconsPE                   = undef
  $scanMaxRecHWP3                   = undef
  $scanPCREMatchLimit               = undef
  $scanPCRERecMatchLimit            = undef
  $scanPCREMaxFileSize              = undef
  $scanAlertExceedsMax              = undef

  $scanScanOnAccess                 = 'no'
  $scanOnAccessMaxFileSize          = undef
  $scanOnAccessMountPathList        = []
  $scanOnAccessIncludePathList      = []
  $scanOnAccessExcludePathList      = []
  $scanOnAccessExcludeRootUID       = undef
  $scanOnAccessExcludeUIDList       = []
  $scanOnAccessDisableDDD           = undef
  $scanOnAccessPrevention           = undef
  $scanOnAccessExtraScanning        = undef

  $scanBytecode                     = undef
  $scanBytecodeSecurity             = undef
  $scanBytecodeTimeout              = undef

}
