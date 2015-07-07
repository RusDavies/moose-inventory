# Moose::Inventory

The [moose-inventory](https://github.com/RusDavies/moose-inventory) Ruby Gem is a package for managing dynamic inventories, intended for use with [Ansible](http://www.ansible.com/home). 

Note: This software is intended for use on UNIX, Linux, or similar systems.  It will likely not work on Windows, due to some hard-wired search paths - I may fix that in the future, but for now, sorry. 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'moose-inventory'
```

And then execute:

    $ bundle
Or install it yourself as:

    $ gem install moose-inventory

## Configuration
The [moose-inventory](https://github.com/RusDavies/moose-inventory) tool makes use of a simple YAML configuration file.  


###Location
 
The following locations, in descending order of precedence, are  searched for a configuration file:
 1. location passed via the *config* CLI option
 2. ./.moose-tools/inventory/config
 4. ~/.moose-tools/inventory/config
 5. ~/local/etc/moose-tools/inventory/config
 6. /etc/moose-tools/inventory/config

###Format
The file contains a mandatory general section, and at least one environment section. For example: 
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

###The 'general' section
The general section is mandatory, and contains a single parameter **defaultenv**, which points to the name of the default environment section.   This is used in the case when no target environment is specified via the command line. 

###Environment sections
You may add as many environment sections as you desire. The intention is to enable the user to easily manage multiple environments, such as development, staging, production, etc., via a single configuration file.  The name of each environment section must be unique, but can otherwise be any valid YAML tag.

At present,  each environment section contains only a **db** subsection, describing the database connection parameters.  Additional subsections may be added in the future, as functionality increases. 

Each **db** section must include an **adapter** parameter. Currently supported adapter types are sqlite3, mysql, and postresql.  Note, as a matter of portability, only sqlite3 has been exercised via the test suite. 

Additional parameters are also required in the **db** subsection, depending on the adapter type.   For the sqlite3 adapter only a **file** parameter is required.  For both mysql and postgresql, then **host**, **database**, **user**, and **password** parameters are required. 


## Usage

##Missing features
The following desired features are yet to be implemented:
1. Groups as children of groups:
-- Group model shall provide a many-to-many relationship to self.
-- CLI:Group shall provided an addchild method.
-- CLI:Group shall provided a rmchild method.
-- CLI:Group.get method shall display child group relationships.
-- CLI:Group.list method shall display child group relationships.

## Contributing
1. Fork it (https://github.com/RusDavies/moose-inventory/fork )
2. Create your feature branch (git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
