class ntta::confluence::cron ($backup_server = undef) {
	include ::confluence::params

	Cron {
		user     => "root",
		month    => "*",
		monthday => "*",
		ensure => "present",
	}

	cron { "remove_old_backups":
		command => "/usr/bin/find ${::confluence::params::homedir}/application-data/confluence/backups -mtime +14 -exec rm {} \\;",
		hour    => "0",
		minute  => "0",
	}

	if $backup_server != undef {
		cron { "confluence_attachments":
			command => "/usr/bin/rsync -avz --delete ${::confluence::params::homedir}/application-data/confluence/attachments/ rsync://${backup_server}/wiki-attachments",
			hour    => "1",
			minute  => "0",

		}

		cron { "confluence_backups":
			command => "/usr/bin/rsync -avz --delete ${::confluence::params::homedir}/application-data/confluence/backups/ rsync://${backup_server}/wiki-backups",
			hour    => "1",
			minute  => "30",
		}
	}
}
