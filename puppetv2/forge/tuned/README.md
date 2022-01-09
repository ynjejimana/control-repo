# tuned

[![Build Status](https://travis-ci.org/bovy89/tuned.svg?branch=master)](https://travis-ci.org/bovy89/tuned)

#### Table of Contents

1. [Module Description - What the module does and why it is useful](#module-description)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
    1. [Public Classes](#public-classes)
    1. [Public Defined Types](#public-defined-types)

## Module Description

This module manages tuned on RedHat systems. This Puppet module simplifies the task of creating tuned profile and the management of the active one


## Usage

### Basic usage
```puppet
	include ::tuned
```

### Enable a standard profile
```puppet
class {'::tuned':
    active_profile => 'virtual-guest',
}
```

### Define and enable a custom profile
```puppet
class {'::tuned':
    active_profile => 'mongodb',
}

tuned::profile { 'mongodb':
	conf_content => 'template("mymodule/mongodb_tuned.erb")',
	scripts      => {
		'thp.sh' => 'template("mymodule/disable_thp.sh.erb")',
	}
}
```


## Reference

* [Public classes](#public-classes)
* [Public Defined types](#public-defined-types)


#### Public classes

Example:

```puppet
class {'::tuned':
    active_profile => 'virtual-guest',
}
```

### Public Defined types


Example:

```puppet
tuned::profile { 'mongodb':
	conf_content => 'template("mymodule/mongodb_tuned.erb")',
	scripts      => {
		'thp.sh' => 'template("mymodule/disable_thp.sh.erb")',
	}
}
```
