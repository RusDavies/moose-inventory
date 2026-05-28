# moose-inventory

The [moose-inventory](https://github.com/RusDavies/moose-inventory) software is a tool for managing dynamic inventories, intended for use with [Ansible](http://www.ansible.com/home).

Note 1: For many, the really interesting part of this tool will be it's ability to write to the inventory database from within Ansible, as described at the end of this document.  If that's what tickles your fancy, then I encourage you to get a sense of the capability by [jumping to that section first](https://github.com/RusDavies/moose-inventory#writing-to-the-dynamic-inventory-from-ansible). ;o)


Note 2: This software is intended for use on UNIX/Linux systems.  It will likely not work on Windows, due to some hard-wired search paths - I may fix that in the future but, for now, sorry.

## Installation

Note: You may need to install Ruby development headers and database client development packages on your system so native gems can build. On current Fedora releases, the project helper script installs the expected SQLite, MariaDB/MySQL, and PostgreSQL client headers.

The tool is a ruby gem. Assuming that you have ruby on your system, then it can be installed from the command line as follows.

    $ gem install moose-inventory

Note: It may be necessary to first install native build tools and database client development headers before installing the gem or running Bundler.

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
    password_env: "MOOSE_INVENTORY_MYSQL_PASSWORD"

another_example_section:
  db:
    adapter:  "postgresql"
    host:     "localhost"
    database: "grass"
    user:     "cow"
    password_env: "MOOSE_INVENTORY_POSTGRES_PASSWORD"

```

###The *general* section
The general section is mandatory, and contains a single parameter **defaultenv**, which points to the name of the default environment section.

###Environment sections
You may add as many environment sections as you desire. The intention is to enable the user to easily manage multiple environments, such as development, staging, production, etc., via a single configuration file.  The name of each environment section must be unique, but can otherwise be any valid YAML tag.

At present,  each environment section contains only a **db** subsection, describing database connection parameters.  Additional subsections may be added in the future, as functionality increases.

Each **db** section must include an **adapter** parameter. Currently supported adapter types are *sqlite3*, *mysql*, and *postgresql*. The test suite exercises SQLite with a local database file and includes adapter dispatch/error-path smoke coverage for MySQL and PostgreSQL without requiring live database servers.

Additional parameters are also required in the **db** subsection, depending on the adapter type. For the *sqlite3* adapter only a **file** parameter is required; parent directories are created automatically. For both *mysql* and *postgresql*, **host**, **database**, **user**, and either **password_env** or **password** are required.

Prefer **password_env** for MySQL and PostgreSQL configuration. Its value is the name of an environment variable that contains the database password, which keeps reusable configuration files from carrying plaintext credentials:

```sh
export MOOSE_INVENTORY_MYSQL_PASSWORD='use-a-real-secret-here'
moose-inventory --env moose_ops host list
```

The older **password** key is still supported for compatibility, but avoid committing configuration files that contain database passwords. If you must use **password**, keep that configuration file outside version control and restrict its file permissions.


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

###Dry-run and plan output
Mutating commands support a `--dry-run` option.  This renders the same kind of progress output as the real command, but does not write anything to the database.  This is useful when checking inventory surgery before applying it, particularly for operations that affect automatic `ungrouped` associations or child-group cleanup.

Examples:

    $ moose-inventory host add web01 --groups web --dry-run
    Add host 'web01':
      - Creating host 'web01'...
        - OK
      - Adding association {host:web01 <-> group:web}...
        - OK
      - All OK
    Dry run complete. No changes applied.
    Succeeded

    $ moose-inventory group rm --recursive old_parent_group --dry-run
    $ moose-inventory host addvar web01 owner=russ env=prod --dry-run
    $ moose-inventory group addhost web web01 web02 --dry-run
    $ moose-inventory group rmchild --delete-orphans parent_group child_group --dry-run

The following mutating command families support `--dry-run`:

 1. `host add` and `host rm`
 2. `group add` and `group rm`
 3. `host addvar`, `host rmvar`, `group addvar`, and `group rmvar`
 4. `host addgroup`, `host rmgroup`, `group addhost`, and `group rmhost`
 5. `group addchild` and `group rmchild`

For automation and review workflows, dry-run events can also be emitted as YAML, JSON, or pretty JSON with `--plan-format`.  This option requires `--dry-run`; without it, the command aborts before making changes.

    $ moose-inventory host add web01 --groups web --dry-run --plan-format pjson
    {
      "command": "host add",
      "dry_run": true,
      "changes_applied": false,
      "events": [
        {
          "type": "host_started",
          "payload": {
            "name": "web01"
          }
        }
      ]
    }

The actual `events` array includes the full ordered plan for the command.  Each event has a `type` and a `payload`, so scripts can inspect planned host, group, variable, association, automatic `ungrouped`, and child-group cleanup actions without scraping human-readable output.

###Import and export snapshots
The full inventory can be exported as a portable snapshot.  The snapshot contains a version number, hosts, host variables, host-to-group memberships, host/group tags, groups, group variables, and child-group relationships.  It is intended for review, backup, migration, and automation workflows.

    $ moose-inventory --format yaml export inventory.yml
    Exported inventory snapshot to inventory.yml.

    $ moose-inventory --format pjson export
    {
      "version": 1,
      "hosts": {
        "web01": {
          "groups": [
            "web"
          ],
          "tags": [
            "prod"
          ],
          "vars": {
            "env": "prod"
          }
        }
      },
      "groups": {
        "web": {
          "children": [],
          "tags": [
            "frontend"
          ],
          "vars": {
            "role": "frontend"
          }
        }
      }
    }

Snapshots can be imported from YAML or JSON.  Import validates the file before writing anything.  It rejects malformed snapshots, unknown host/group references, unsupported fields, invalid variable shapes, and circular child-group hierarchies.

    $ moose-inventory import inventory.yml
    Imported inventory snapshot from inventory.yml.
    Created hosts: 1
    Created groups: 1
    Variables changed: 2
    Associations added: 1

Import is additive and update-oriented: it creates missing hosts and groups, adds missing associations and tags, and creates or updates variables found in the snapshot.  It does not delete existing inventory records that are absent from the file.  Use a fresh database when you want the imported snapshot to be the whole world, because databases are notoriously bad at guessing intent.

###Inventory doctor
The `doctor` command runs read-only inventory health checks and exits with a non-zero status if it finds issues.  This makes it suitable for CI checks, release gates, and pre-change reviews.

    $ moose-inventory doctor
    Inventory doctor found no issues.

When findings are present, the human-readable output lists each issue with a severity and check id:

    $ moose-inventory doctor
    Inventory doctor found 2 issue(s):
    - [warning] host_only_in_ungrouped: Host 'web01' is only in automatic group 'ungrouped'.
    - [warning] orphaned_group: Group 'old_web' has no parents and no hosts.

For automation, use `--format yaml`, `--format json`, or `--format pjson` on the doctor command itself:

    $ moose-inventory doctor --format pjson
    {
      "ok": false,
      "issue_count": 1,
      "issues": [
        {
          "id": "host_only_in_ungrouped",
          "severity": "warning",
          "message": "Host 'web01' is only in automatic group 'ungrouped'.",
          "subject": "web01"
        }
      ]
    }

Current doctor checks include missing database configuration, plaintext database passwords, hosts only in `ungrouped`, orphaned groups, empty groups, duplicate-ish names, invalid variable records, and circular child-group relationships.

###Metadata tags
Hosts and groups can carry metadata tags that are separate from Ansible variables.  Use tags for operational labels such as environment, owner, lifecycle, location, role, or criticality when you want metadata without exposing it as inventory variables.

    $ moose-inventory host addtag web01 prod critical owner-platform
    Added host tag(s) to 'web01': prod, critical, owner-platform.

    $ moose-inventory host listtags web01
    Host 'web01' tags: critical, owner-platform, prod

    $ moose-inventory host rmtag web01 critical
    Removed host tag(s) from 'web01': critical.

Groups support the same tag commands:

    $ moose-inventory group addtag web frontend public-edge
    $ moose-inventory group listtags web --format json

Tag names are normalized to lowercase, deduplicated per host/group, and stored in portable join tables.  Tag add/remove operations are audited when they change state.  Querying/filtering by tags is intentionally left to the next query/filter backlog item so this slice keeps metadata storage and inspection simple.

###Audit log / change history
Moose Inventory records append-only audit events for successful mutating CLI commands.  Dry-run commands are intentionally excluded, because planned changes are already available through `--plan-format` and did not actually mutate inventory state.

Audit events record when the change happened, the local actor from `USER`, the command/action, the entity type/name, and structured operation details.  The audit log is deliberately small: it is for debugging and accountability, not yet a full rollback system.

List recent events in a human-readable form:

    $ moose-inventory audit list
    12 2026-05-28T17:01:02Z host add host=app01 action=add

Machine-readable output is available for scripts and support bundles:

    $ moose-inventory audit list --format yaml
    $ moose-inventory audit list --format json
    $ moose-inventory audit list --format pjson

The default limit is 20 events; use `--limit` to inspect more history:

    $ moose-inventory audit list --limit 100

###Database lifecycle commands
Moose Inventory records a small schema metadata table and exposes database lifecycle commands under `db`.  These commands are intentionally conservative: they inspect, create missing schema metadata, and back up SQLite databases, but they do not silently rewrite production databases into a modern art installation.

    $ moose-inventory db status
    Adapter: sqlite3
    Schema version: 3
    Expected schema version: 3
    SQLite file: /home/russ/.moose/db/dev.db
    Tables:
    - hosts: present
    - hostvars: present
    - groups: present

    $ moose-inventory db doctor
    Database doctor found no issues.

    $ moose-inventory db migrate
    Database schema is at version 3.

`db migrate` is currently a lightweight schema bootstrap/metadata command.  It creates any missing known tables and records the current schema version.  Future release migrations should extend this path instead of hiding schema changes inside unrelated commands.  Moose Inventory refuses to open or migrate a database whose recorded schema version is newer than the tool supports; upgrade the tool instead of letting old code write to a future schema.  `db doctor` reports missing known tables in a dirty or partially migrated database.

SQLite users can create a direct database-file backup:

    $ moose-inventory db backup ./backup/moose-inventory.sqlite3
    Backed up database to /absolute/path/backup/moose-inventory.sqlite3.

`db backup` is currently supported for SQLite only.  For MySQL and PostgreSQL, use native database tools such as `mysqldump` or `pg_dump`, because those engines already have adult supervision built in.

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

Host listing can also be filtered by group, metadata tag, and host variable.  Multiple comma-separated values are treated as an AND filter: the host must match all requested groups, all requested tags, and all requested variable key/value pairs.

    $ moose-inventory host list --group web --tag prod --var os=fedora --format yaml

Variable filters use `key=value` syntax.  Metadata tags appear under a `tags` section when present; hosts without tags keep the older compact output.  Group-side listing filters are still part of the remaining query/filter backlog, because one haunted query surface per slice is plenty.

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

###Read-only console
For human browsing, Moose Inventory includes a small read-only console.  It is intentionally conservative: the first console slice lets operators inspect inventory state, tags, and recent audit events, but does not mutate records.

    $ moose-inventory console
    Moose Inventory console (read-only). Type help or quit.

Useful console commands include:

    help
    hosts
    groups
    host web01
    group web
    tags host web01
    tags group web
    audit 10
    quit

Use the normal CLI commands for edits.  Future interactive mutation can be added with confirmation, dry-run, and audit semantics instead of improvising a tiny foot-gun in a prompt loop.

Removing variables, groups, and hosts is just as easy.  In the following examples, the output is again omitted for compactness; the reader is encouraged to work along to experience the tool.  Note, that although we show how to remove the variables, it is not strictly necessary to do so in this example, since deleting hosts and groups would delete all associated variables anyway.

By default, deleting a group preserves its child groups as root groups. Use `group rm --recursive` when child groups that become orphaned should also be deleted. Similarly, `group rmchild --delete-orphans` removes a parent-child association and deletes the child subtree only when it becomes orphaned by that removal. Hosts whose last group is deleted are automatically moved to `ungrouped`.

    $ moose-inventory group rmvar group1 location
    $ moose-inventory group rm group1 group2 group3
    $ moose-inventory group rm --recursive old_parent_group
    $ moose-inventory group rmchild --delete-orphans parent_group child_group
    $ moose-inventory host rmvar
    $ moose-inventory host rmvar host1 owner id
    $ moose-inventory host rm host1 host2 host3

###CI/CD integration examples
The `examples/ci/` directory contains a pull-request review pattern for inventory changes that does not require production database credentials.  It imports a proposed snapshot into a temporary SQLite database, runs `doctor`, exports a canonical snapshot, lists hosts, and writes an Ansible-compatible inventory artifact.

Run the example locally with:

    $ MOOSE_INVENTORY_CMD="bundle exec ruby -Ilib bin/moose-inventory" \
        examples/ci/scripts/validate-inventory-snapshot.sh \
        examples/ci/inventory/example-snapshot.yml \
        tmp/inventory-ci-artifacts

The script writes:

    tmp/inventory-ci-artifacts/doctor.txt
    tmp/inventory-ci-artifacts/inventory.yml
    tmp/inventory-ci-artifacts/hosts.json
    tmp/inventory-ci-artifacts/ansible-inventory.json

`examples/ci/github-actions/inventory-review.yml` shows the same pattern as a GitHub Actions workflow.  It is stored under `examples/` rather than `.github/workflows/` so teams can adapt paths, snapshot locations, artifact names, and deployment rules before enabling it.  Use this as a review gate before applying inventory changes to a shared or production Moose Inventory database; CI should validate proposals, not casually scribble on prod like a bored intern.

### Using moose-inventory with Ansible


The *moose-inventory* tool is compliant with the Ansible specifications for [dynamic inventory sources](http://docs.ansible.com/developing_inventory.html).

The preferred modern integration is the example inventory plugin shipped in `examples/ansible/inventory_plugins/moose_inventory.py`.  Copy or vendor that plugin into your Ansible project, then point `ansible.cfg` at the plugin directory and inventory source file:

```ini
[defaults]
inventory = inventory/moose_inventory.yml
inventory_plugins = inventory_plugins
```

The inventory source file is plain YAML:

```yaml
---
plugin: moose_inventory
executable: moose-inventory
config: ./example.conf
env: dev
```

With those files in place, Ansible can use Moose Inventory directly:

    $ ansible-inventory -i inventory/moose_inventory.yml --list
    $ ansible -i inventory/moose_inventory.yml -u ubuntu us-east-1d -m ping

The plugin calls `moose-inventory` for group and host data, preserving Moose Inventory's own configuration file and environment selection instead of hiding them in a shell wrapper.  The shipped `examples/ansible/` directory contains a complete minimal `ansible.cfg`, inventory source, and plugin file.

A legacy external-inventory shim still works, and remains useful on older Ansible installs or when you want the simplest possible integration.  To make use of *moose-inventory's* multiple environment and configuration file options with the shim approach, use a script as the target for the [external inventory script](http://docs.ansible.com/intro_dynamic_inventory.html). A trivial example may look something like the following.

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


## Development checks

Run the local verification gate before committing changes:

```shell
./scripts/check.sh
```

The check script runs the RSpec suite, enforces the SimpleCov coverage minimum, checks file permissions, queries OSV for locked RubyGems advisories, runs `bundler-audit`, runs `gitleaks` when available, and builds/smoke-tests the packaged gem.

Optional Go-based security tools used by CI can be installed locally with:

```shell
./scripts/ci/install_security_tools.sh
```

That installs `gitleaks` and `osv-scanner` into `tmp/security-tools/bin` unless they are already on `PATH`. Fedora users can also run `./scripts/install_dependencies.sh` to install the native build dependencies and packaged `gitleaks`; `bundler-audit` is installed through Bundler.

## Contributing
1. Fork it (https://github.com/RusDavies/moose-inventory/fork )
2. Create your feature branch (git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request










