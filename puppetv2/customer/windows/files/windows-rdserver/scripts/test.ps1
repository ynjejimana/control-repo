import-module remotedesktop
$RDSroles = get-rdserver -erroraction silentlycontinue
if ( $RDSroles -ne $null ) { 
  Exit 1
}
