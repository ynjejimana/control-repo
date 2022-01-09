# The baseline for module testing used by Puppet Labs is that each manifest
# should have a corresponding test manifest that declares that class or defined
# type.
#
# Tests are then run by using puppet apply --noop (to check for compilation
# errors and view a log of events) or by fully applying the test in a virtual
# environment (to compare the resulting system state to the desired state).
#
# Learn more about module testing here:
# http://docs.puppetlabs.com/guides/tests_smoke.html
#
include ::tuned

class {'::tuned':
    tuned_ensure => 'absent',
}

class {'::tuned':
    active_profile => 'virtual-guest',
}


class {'::tuned':
    active_profile => 'mongodb',
}

tuned::profile { 'mongodb':
    conf_content => 'test',
    scripts      => {
        'thp.sh' => '!#/bin/bash exit 1',
    },
}
