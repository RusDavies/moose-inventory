# moose-inventory

The [moose-inventory](https://github.com/RusDavies/moose-inventory) software is a tool for managing dynamic inventories, intended for use with [Ansible](http://www.ansible.com/home). 

Note 1: For many, the really interesting part of this tool will be it's ability to write to the inventory database from within Ansible, as described at the end of this document.  If that's what tickles your fancy, then I encourage you to get a sense of the capability by [jumping to that section first](https://github.com/RusDavies/moose-inventory#writing-to-the-dynamic-inventory-from-ansible). ;o)


Note 2: This software is intended for use on UNIX/Linux systems.  It will likely not work on Windows, due to some hard-wired search paths - I may fix that in the future but, for now, sorry. 

## Installation

The tool is a ruby gem. Assuming that you have ruby on your system, then it can be installed from the command line as follows.

    $ gem install moose-inventory

It can also be installed by adding the following line to a Gemfile and then executing `bundle`:

```ruby
gem 'moose-inventory'
```


## Configuration
The [moose-inventory](https://github.com/RusDavies/moose-inventory) tool makes use of a simple YAML configuration file.  


###File Location
 
The following locations, in descending order of precedence, are  searched for a configuration file:

 1. location passed via the `--config` option
 2. ./.moose-tools/inventory/config
 4. ~/.moose-tools/inventory/config
 5. ~/local/etc/moose-tools/inventory/config
 6. /etc/moose-tools/inventory/config

###Format
The file consists of a mandatory *general* section, and at least one *environment* section. For example: 
```yaml
---
general:
  defaultenv: moose_dev

moose_dev: 
  db:
    adapter: "sqlite3"
    file:    "~/.moose/db/dev.db"

moose_ops:
  db:
    adapter:  "mysql"
    host:     "localhost"
    database: "water"
    user:     "duck"
    password: "quack"

another_example_section:
  db:
    adapter:  "postgresql"
    host:     "localhost"
    database: "grass"
    user:     "cow"
    password: "moo"

```

###The *general* section
The general section is mandatory, and contains a single parameter **defaultenv**, which points to the name of the default environment section.   

###Environment sections
You may add as many environment sections as you desire. The intention is to enable the user to easily manage multiple environments, such as development, staging, production, etc., via a single configuration file.  The name of each environment section must be unique, but can otherwise be any valid YAML tag.

At present,  each environment section contains only a **db** subsection, describing database connection parameters.  Additional subsections may be added in the future, as functionality increases. 

Each **db** section must include an **adapter** parameter. Currently supported adapter types are *sqlite3*, *mysql*, and *postresql*.  Note, as a matter of portability, only *sqlite3* is exercised via the test suite. 

Additional parameters are also required in the **db** subsection, depending on the adapter type.   For the *sqlite3* adapter only a **file** parameter is required.  For both *mysql* and *postgresql*, then **host**, **database**, **user**, and **password** are the required parameters. 


## Usage
### The help system
The tool itself provides a convenient help feature.  For example, try each of the following,

    $ moose-inventory help
    $ moose-inventory help group
    $ moose-inventory group help add

###Global switches

#### Option `--config <FILE>`
The `--config` flag sets the configuration file to be used.  If specified, then the file must exist. This takes precedence over all other config files in other locations.  If not provided, then the default is to search the locations previously mentioned.

For example, 

    $ moose-inventory --config ./mystuff.conf host list

#### Option `--env <SECTION>`
The *--env* flag sets the section in the configuration file to be used as the environment configuration.  If set, then the section must exist.  If not set, then what ever default is provided by the **defaultenv** parameter will be used. 

For example, 

    $ moose-inventory --env my_section host list

#### Option `--format <yaml|json|pjson>`
The `--format` switch changes the output format for *list* and *get* operations.  Valid formats are yaml, json, pjson (i.e. pretty JSON).   If the switch is not given, then the default is json.

For example,

    $ moose-inventory --format yaml host list
    ---
    :test1:
      :groups:
        - ungrouped

###Transactional Behaviour
The *moose-inventory* tool performs database operations in a transactional manner.  That is to say, either all operations of a command succeed, or they are all rolled back.  

###Walk-through example
This walk-through goes through the process of creating three hosts and three groups, assigning variables to some of each, and then associating hosts with groups.  Once done, each association, variable, group, and host are removed.  

We start by creating three hosts, in this case named *host1*,  *host2*, and *host3*.  Note, we can add as many hosts as we desire via this single command.  Also, although we have used short names here, we could equally have used fully qualified names. 

    $ moose-inventory add host host1 host2 host3
    Add host 'host1':
      - creating host 'host1'...
        - OK
      - add automatic association {host:host1 <-> group:ungrouped}...
        - OK
      - all OK
    Add host 'host2':
      - creating host 'host2'...
        - OK
      - add automatic association {host:host2 <-> group:ungrouped}...
        - OK
      - all OK
    Add host 'host3':
      - creating host 'host3'...
        - OK
      - add automatic association {host:host3 <-> group:ungrouped}...
        - OK
      - all OK
    Succeeded.

Notice that each host is initially associated with an automatic group, *ungrouped*.   

Now we can list our hosts, to see that they are stored as expected.  In this example, we will request the output be formatted as YAML.  If we didn't specify a format, then it would default to regular JSON.

    $ moose-inventory host list --format pjson
    {
      "host1": {
        "groups": [
          "ungrouped"
        ]
      },
      "host2": {
        "groups": [
          "ungrouped"
        ]
      },
      "host3": {
        "groups": [
          "ungrouped"
        ]
      }
    }

The *host list* command simply lists all hosts, in the order that they were entered into the database.  We can also get a specific host, or hosts, by name.  In this example, we'll get only *host3* and *host1*, outputting the result in YAML.  

    $ moose-inventory host get host3 host1 --format yaml
    ---
    :host3:
      :groups:
      - ungrouped
    :host1:
      :groups:
      - ungrouped

Now we'll add some host variables.  Again, we can add as many variables to a host as we desire.

    $ moose-inventory host addvar host1 owner=russell id=12345
    Add variables 'owner=russell,id=12345' to host 'host1':
      - retrieve host 'host1'...
        - OK
      - add variable 'owner=russell'...
        - OK
      - add variable 'id=12345'...
        - OK
      - all OK
    Succeeded.
    
    $ moose-inventory host addvar host2 owner=caroline id=54321
    Add variables 'owner=caroline,id=54321' to host 'host2':
      - retrieve host 'host2'...
        - OK
      - add variable 'owner=caroline'...
        - OK
      - add variable 'id=54321'...
        - OK
      - all OK
    Succeeded.

Let's list our hosts again, to see what that looks like.

    $ moose-inventory host list --format yaml
    ---
    :host1:
      :groups:
      - ungrouped
      :hostvars:
        :owner: russell
        :id: '12345'
    :host2:
      :groups:
      - ungrouped
      :hostvars:
        :owner: caroline
        :id: '54321'
    :host3:
      :groups:
      - ungrouped

As you can see, the hosts with variables each have a new section, hostvars, in which those variables are listed.  Try also with *--format pjson*.

We can do the same with groups.  In the following example, the output has been omitted for compactness. Nevertheless, you will see that the form of the commands is as for hosts.  Of note, when listing the groups, you will see that the *ungrouped* group is shown.   This is an automatic group which cannot be manipulated manually. 

    $ moose-inventory group add group1 group2 group3
    $ moose-inventory group list --format yaml
    $ moose-inventory group get ungrouped group2 --format yaml
    $ moose-inventory group addvar group1 location=usa
    $ moose-inventory group addvar group2 location=europe

At this point, we have three hosts and three groups, some of each with variables.  Let's now associate hosts with groups.  We can either associate one or more hosts with a group,

    $ moose-inventory group addhost group1 host1 host2 
    Associate group 'group1' with host(s) 'host1,host2':
      - retrieve group 'group1'...
        - OK
      - add association {group:group1 <-> host:host1}...
        - OK
      - remove automatic association {group:ungrouped <-> host:host1}...
        - OK
      - add association {group:group1 <-> host:host2}...
        - OK
      - remove automatic association {group:ungrouped <-> host:host2}...
        - OK
      - all OK
    Succeeded.

or one or more groups with a host,

    $ moose-inventory host addgroup host3 group2 group3 
    Associate host 'host3' with groups 'group2,group3':
      - Retrieve host 'host3'...
        - OK
      - Add association {host:host3 <-> group:group2}...
        - OK
      - Add association {host:host3 <-> group:group3}...
        - OK
      - Remove automatic association {host:host3 <-> group:ungrouped}...
        - OK
      - All OK
    Succeeded

Notice in each of the two above excepts, the group *ungrouped* is automatically removed from each host, as it gains one or more group associations.  Now we can again list our groups, to see what we have.

    $ moose-inventory group list --format yaml
    ---
    :ungrouped: {}
    :group1:
      :hosts:
      - host1
      - host2
      :groupvars:
        :location: usa
    :group2:
      :hosts:
      - host3
    :group3:
      :hosts:
      - host3

We can also list hosts, to get the host-centric view.

    ---
    :host1:
      :groups:
      - group1
      :hostvars:
        :owner: russell
        :id: '12345'
    :host2:
      :groups:
      - group1
      :hostvars:
        :owner: caroline
        :id: '54321'
    :host3:
      :groups:
      - group2
      - group3

Removing variables, groups, and hosts is just as easy.  In the following examples, the output is again omitted for compactness; the reader is encouraged to work along to experience the tool.  Note, that although we show how to remove the variables, it is not strictly necessary to do so in this example, since deleting hosts and groups would delete all associated variables anyway. 

    $ moose-inventory group rmvar group1 location
    $ moose-inventory group rm group1 group2 group3
    $ moose-inventory host rmvar
    $ moose-inventory host rmvar host1 owner id
    $ moose-inventory host rm host1 host2 host3

### Using moose-inventory with Ansible


The *moose-inventory* tool is compliant with the Ansible specifications for [dynamic inventory sources](http://docs.ansible.com/developing_inventory.html).

However, to make use of *moose-inventory's* multiple environment and configuration file options, a shim script should be used as the target for the [external inventory script](http://docs.ansible.com/intro_dynamic_inventory.html). A trivial example may look something like the following.  

```shell
#!/bin/bash

CONF='./example.conf'
ENV='dev'

moose-inventory --config $CONF --env $ENV "$@"

exit $?
```

**IMPORTANT**: Take care to notice that "$@" is the quoted form.  In fact, $@ and "$@" behave differently in how they handle white space.  If you expect spaces in your variable names or values, such as in the following example, then you must use the quoted form "$@".

    $ ./shim.sh host add example
    $ ./shim.sh host addvar example "my var"="hello world"
     

When Ansible calls the external inventory script, it passes certain parameters, which *moose-inventory* automatically recognises and responds to.  The Ansible parameters, and their equivalent *moose-inventory* parameters are shown below. 

Ansible          | moose-inventory
---------------- |-------------
`--list`         | `--ansible group list`    
`--host HOSTNAME` | `--ansible host listvars HOSTNAME`

Note, the above conversions are performed automatically within *moose-inventory*. 

With *moose-inventory* installed and configured, and a shim script (e.g. *shim.sh*) in place, then integration with Ansible can be acheived via Ansible's `-i <file>` option.

    ansible -i shim.sh -u ubuntu us-east-1d -m ping

Alternatively, if using an [Ansible configuration file](http://docs.ansible.com/intro_configuration.html), then one may set the [inventory](http://docs.ansible.com/intro_configuration.html#inventory) option,

    inventory = ./shim.sh
    
Yet another option is to copy the shim script to */etc/ansible/hosts* and `chmod +x` it.  However, since this would essentially fix the config file and environment used, doing so would defeat the flexibility intended for *moose-inventory*.    

#### Writing to the dynamic inventory from Ansible
A useful aspect of dynamic inventories is the possibility of writing data to the inventory. To persist data from Ansible to the inventory, simply call the shim script via a local_action command, for example:

```shell
- set_fact: mydata="Hello world"
- local_action: command shim.sh host addvar {{ inventory_hostname }} mydata="{{ mydata }}" 
```

 
## Contributing
1. Fork it (https://github.com/RusDavies/moose-inventory/fork )
2. Create your feature branch (git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request


    








