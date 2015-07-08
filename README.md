# moose-inventory

The [moose-inventory](https://github.com/RusDavies/moose-inventory) Ruby Gem is a package for managing dynamic inventories, intended for use with [Ansible](http://www.ansible.com/home). 

Note: This software is intended for use on UNIX, Linux, or similar systems.  It will likely not work on Windows, due to some hard-wired search paths - I may fix that in the future but, for now, sorry. 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'moose-inventory'
```

And then execute:

    $ bundle
Or install it yourself as:
```ruby
$ gem install moose-inventory
```

## Configuration
The [moose-inventory](https://github.com/RusDavies/moose-inventory) tool makes use of a simple YAML configuration file.  


###File Location
 
The following locations, in descending order of precedence, are  searched for a configuration file:

 1. location passed via the *-<sp>-config* CLI option
 2. ./.moose-tools/inventory/config
 4. ~/.moose-tools/inventory/config
 5. ~/local/etc/moose-tools/inventory/config
 6. /etc/moose-tools/inventory/config

###Format
The file consists of a mandatory *general* section, and at least one environment section. For example: 
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
The tool itself provides a convenient help feature.  For example, 

    > moose-inventory help
    Commands:
      moose-inventory group ACTION    # Manipulate groups in…
      moose-inventory help [COMMAND]  # Describe available c…
      ⋮

and, 

    > moose-inventory help group
    Commands:
      moose-inventory group add NAME  # Add a group NAME to …
      moose-inventory group list      # List the groups, tog…
      ⋮

and,

    > moose-inventory group help add
    Usage:
      moose-inventory add NAME
    
    Options:
      [--hosts=HOSTS]  
    
    Add a group NAME to the inventory

###Top level switches
Not described in the built-in help system are a handful of top-level switches, as follows. 

#### - -config
The *--config* flag sets the configuration file to be used.  If specified, then the file must exist. This takes precedence over all other config files in other locations.  If not provided, then the default is to see in standard locations, see later.

For example, 

    > moose-inventory --config ./my_conf host list

#### - -env
The *--env* flag sets the section in the configuration file to be used as the environment configuration.  If set, then the section must exist.  If not set, then what ever default is provided in the general::defaultenv parameter of the configuration file will be used. 

For example, 

    > moose-inventory --env my_section host list

#### - - format
The *--format* switch changes the output format from *list* and *get* operations.  Valid formats are yaml, json, pjson (i.e. pretty JSON).   If the switch is not given, then the default is json. 

For example,

    > moose-inventory --format yaml host list
    ---
    :test1:
      :groups:
        - ungrouped

###Transactional Behaviour
The *moose-inventory* tool performs database operations in a transactional manner.  That is to say, either all operations of a command succeed, or they are all rolled back.  

###Walk-through examples
In this example, we will walk through the process of creating two hosts and two groups, assigning variables to each, and then then associating hosts with groups.  Once done, we will then remove each association, variable, group and host.  

We start by creating three hosts, in this case named *host1*,  *host2*, and *host3*.  Note, we can add as many hosts as we desire via this single command.  Also, although we have used short names here, we could equally have used fully qualified names. 

    > moose-inventory add host host1 host2 host3
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

    > moose-inventory host list --format pjson
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

    > moose-inventory host get host3 host1 --format yaml
    ---
    :host3:
      :groups:
      - ungrouped
    :host1:
      :groups:
      - ungrouped

Now we'll add some host variables.  Again, we can add as many variables to a host as we desire.

    > moose-inventory host addvar host1 owner=russell id=12345
    Add variables 'owner=russell,id=12345' to host 'host1':
      - retrieve host 'host1'...
        - OK
      - add variable 'owner=russell'...
        - OK
      - add variable 'id=12345'...
        - OK
      - all OK
    Succeeded.
    
    > moose-inventory host addvar host2 owner=caroline id=54321
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

    > moose-inventory host list --format yaml
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

    > moose-inventory group add group1 group2 group3
    > moose-inventory group list --format yaml
    > moose-inventory group get ungrouped group2 --format yaml
    > moose-inventory group addvar group1 location=usa
    > moose-inventory group addvar group2 location=europe

At this point, we have three hosts and three groups, some of each with variables.  Let's now associate hosts with groups.  We can either associate one or more hosts with a group,

    > moose-inventory group addhost group1 host1 host2 
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

    > moose-inventory host addgroup host3 group2 group3 
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

    > moose-inventory group list --format yaml
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

    > moose-inventory group rmvar group1 location
    > moose-inventory group rm group1 group2 group3
    > moose-inventory host rmvar
    > moose-inventory host rmvar host1 owner id
    > moose-inventory host rm host1 host2 host3

### Using moose-inventory with Ansible
For integration with Ansible, a shim script should be used, in order to set the correct configuration file, environment, etc.  

A trivial shim script, to be registered with Ansible as the [external inventory script](http://docs.ansible.com/intro_dynamic_inventory.html), may look like this, 

    #!/bin/bash
     
    moose-inventory --config ./example.conf \
                    --env dev \
                    $@
When Ansible calls the external inventory script, it does so using the certain parameters, which *moose-inventory* recognises.  The Ansible parameters, and their equivalent *moose-inventory* native parameters are shown below. 

| Ansible params       | moose-inventory params|
| ------------- |:-------------:|
| -<sp>-hosts   | host list    |
| -<sp>-hosts HOST | host get HOST|
| --groups | group list      |
Note, the above conversions are done automatically by the tool, and are included here only for reference. 

##Missing features
The following desired features are yet to be implemented:

1. Top level switches should be described by the built-in help system.
2. Groups of groups

## Contributing
1. Fork it (https://github.com/RusDavies/moose-inventory/fork )
2. Create your feature branch (git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request


    








