class windows::windows-motd::default ($message) {

    registry_value { 'HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System\LegalNoticeCaption':
        type => string,
        data => 'WARNING',
				        }


    registry_value { 'HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System\LegalNoticeText':
        type => string,
        data => $message,
}
}

