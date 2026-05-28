# -*- coding: utf-8 -*-
# Copyright: (c) Russell Davies
# MIT License

from __future__ import annotations

import json
import subprocess

from ansible.errors import AnsibleParserError
from ansible.plugins.inventory import BaseInventoryPlugin

DOCUMENTATION = r'''
    name: moose_inventory
    plugin_type: inventory
    short_description: Moose Inventory plugin
    description:
        - Loads inventory from the C(moose-inventory) command line tool.
        - Keeps Moose Inventory configuration and environment selection in YAML instead of a shell shim.
    options:
        plugin:
            description: Token that ensures this is a source file for this plugin.
            required: true
            choices: ['moose_inventory']
        executable:
            description: Moose Inventory executable path.
            required: false
            default: moose-inventory
        config:
            description: Moose Inventory config file passed to C(--config).
            required: false
        env:
            description: Moose Inventory environment section passed to C(--env).
            required: false
'''

EXAMPLES = r'''
plugin: moose_inventory
executable: moose-inventory
config: ./example.conf
env: dev
'''


class InventoryModule(BaseInventoryPlugin):
    NAME = 'moose_inventory'

    def verify_file(self, path):
        return super().verify_file(path) and path.endswith(('moose_inventory.yml', 'moose_inventory.yaml'))

    def parse(self, inventory, loader, path, cache=True):
        super().parse(inventory, loader, path, cache=cache)
        config = self._read_config_data(path)
        executable = config.get('executable', 'moose-inventory')
        moose_config = config.get('config')
        env = config.get('env')

        groups = self._run_moose(executable, moose_config, env, ['--ansible', 'group', 'list'])
        hosts = self._run_moose(executable, moose_config, env, ['host', 'list'])

        self._apply_groups(groups)
        self._apply_hosts(hosts)

    def _run_moose(self, executable, config, env, args):
        command = [executable]
        if config:
            command.extend(['--config', config])
        if env:
            command.extend(['--env', env])
        command.extend(args)

        try:
            completed = subprocess.run(command, check=True, capture_output=True, text=True)
        except (OSError, subprocess.CalledProcessError) as error:
            raise AnsibleParserError('moose-inventory command failed: %s' % error) from error

        try:
            return json.loads(completed.stdout or '{}')
        except json.JSONDecodeError as error:
            raise AnsibleParserError('moose-inventory returned invalid JSON: %s' % error) from error

    def _apply_groups(self, groups):
        for group_name, payload in groups.items():
            self.inventory.add_group(group_name)
            for host_name in payload.get('hosts', []):
                self.inventory.add_host(host_name, group=group_name)
            for child_name in payload.get('children', []):
                self.inventory.add_group(child_name)
                self.inventory.add_child(group_name, child_name)
            for key, value in payload.get('vars', {}).items():
                self.inventory.set_variable(group_name, key, value)

    def _apply_hosts(self, hosts):
        for host_name, payload in hosts.items():
            self.inventory.add_host(host_name)
            for group_name in payload.get('groups', []):
                self.inventory.add_group(group_name)
                self.inventory.add_host(host_name, group=group_name)
            for key, value in payload.get('hostvars', {}).items():
                self.inventory.set_variable(host_name, key, value)
