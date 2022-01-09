class { 'logstash':
  jvm_options => [
    '-Dcom.sun.management.jmxremote',
    '-Dcom.sun.management.jmxremote.port=9010',
    '-Dcom.sun.management.jmxremote.authenticate=false',
    '-Dcom.sun.management.jmxremote.ssl=false',
  ]
}

logstash::configfile { 'basic_config':
  content => 'input { tcp { port => 2000 } } output { null {} }'
}

logstash::plugin {'logstash-input-jmx':
  environment => 'LS_JVM_OPTS="-Xms1g -Xmx1g"',
}
