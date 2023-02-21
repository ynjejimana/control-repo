define common::cron::job (
	$command,
	$ensure = 'present',
	$hour = '*',
	$minute = '*',
	$month = '*',
	$monthday = '*',
	$user = 'root',
	$weekday = '*',
) {

	cron {  $name:
		ensure 		=> $ensure,
		command 	=> $command,
		user     => $user,
		hour     => $hour,
		minute   => $minute,
		month    => $month,
		monthday	=> $monthday,
		weekday		=> $weekday,
	}
}

