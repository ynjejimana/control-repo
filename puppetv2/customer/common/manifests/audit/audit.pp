class common::audit::audit (
  $audit_rules_file = "/etc/audit/audit.rules",
  $audit_config_file = "/etc/audit/auditd.conf",
  $audit_log_group = "root",
  $enable_root_only = undef
) {
	#Requires rsyslog class and graylog template applied
	require common::rsyslog::client

#	file { '/etc/profile.d/bashaudit.sh':
#	  	source => "puppet:///modules/common/audit/bash_audit",
#      onlyif  => "/usr/bin/test ! -e /root/.bash_audit", #do not apply to servers that have old common::audit::audit
# 	}


if $common::audit::audit::enable_root_only == true {
  $bash_audit_source = "bash_audit_root_only"
}

else {
    $bash_audit_source = "bash_audit"
}

  file { '/tmp/bash_audit.puppet':
    #source => "puppet:///modules/common/audit/bash_audit",
    source => "puppet:///modules/common/audit/${bash_audit_source}",
    owner => 'root',
    group => 'root',
    mode => '0640',
  }

  exec {"enable bash_audit":
   #command => "/bin/cp /tmp/bash_audit.puppet /etc/profile.d/bash_audit.sh",
    command => "/bin/cp /tmp/bash_audit.puppet /etc/profile.d/bash_audit.sh && /bin/chmod 644 /etc/profile.d/bash_audit.sh && /bin/touch /root/.bash_audit",
    require => File["/tmp/bash_audit.puppet"],
    onlyif => "/usr/bin/test ! -e /root/.bash_audit",
  }

	package {'audit':
		ensure => present,
		before => [File[$audit_rules_file],File[$audit_config_file],Service['auditd']],
	}

	service {'auditd':
		ensure    => running,
		enable    => true,
		restart   => '/sbin/service auditd restart',
		subscribe	=> File[$audit_rules_file]
	}


	file { $audit_rules_file:
		source => "puppet:///modules/common/audit/audit.rules",
		owner  => 'root',
		group  => 'root',
		mode   => '0640',
	}

	file { $audit_config_file:
		content => template("common/audit/auditd.conf.erb"),
		owner  => 'root',
		group  => 'root',
		mode   => '0640',
	}


	rsyslog::imfile { 'audit-log-remote':
		file_name     => '/var/log/audit/audit.log',
		file_tag      => 'auditd',
		file_facility => 'authpriv',
	}
	


}
