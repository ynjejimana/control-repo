# Delete WinRM HTTPS listener

$HTTPSlistener=(Get-ChildItem WSMan:\localhost\Listener | Where {$_.Keys -like "TRANSPORT=HTTPS"}).name

if $HTTPSlistener -ne $null {

remove-item WSMan:\localhost\Listener\$HTTPSlistener -recurse -force

}
