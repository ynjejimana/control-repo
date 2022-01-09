define esbu::postfix::configparams ($configname,$configfilename,$valuetype)

{

  postfix::config { "${configname}":
    value => "${valuetype}:/etc/postfix/${configfilename}",
    require => File["/etc/postfix/${configfilename}"],
  }

  exec {"rebuild ${configname}":
    subscribe => File["/etc/postfix/${configfilename}"],
    command => "/usr/sbin/postmap /etc/postfix/${configfilename}",
    cwd => "/etc/postfix",
    refreshonly => true,
  }

  file {"/etc/postfix/${configfilename}":
    content => template("esbu/postfix/${configfilename}.erb"),
  }


}
