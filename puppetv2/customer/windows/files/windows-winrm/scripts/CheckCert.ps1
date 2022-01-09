# Test if the certificate that is bound to the HTTPS listener is due to expire
# Return exit code of 1 if HTTPS listener doesnt exist or if cert hasnt expired
#

$HTTPSlistener=(Get-ChildItem WSMan:\localhost\Listener | Where {$_.Keys -like "TRANSPORT=HTTPS"}).name

if ( $HTTPSlistener -eq $null ) {
    Exit 1
} else {

  # Get the expiry date for the certificate bound to the HTTPS listener.

  $thumbprint=(get-childitem WSMan:\localhost\Listener\$HTTPSlistener\CertificateThumbprint).value
  $CertificateExpiryDate = (get-childitem Cert:\LocalMachine\My\$thumbprint).GetExpirationDateString()

  if ( (get-date).AddDays(5) -gt (get-date $CertificateExpiryDate) -eq $false) {
    Exit 1
  }
}
