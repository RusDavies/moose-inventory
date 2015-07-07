#!/bin/bash
moose-inventory help
moose-inventory help group
moose-inventory group help add
moose-inventory host add host1 host2 host3
moose-inventory host list --format pjson
moose-inventory host get host3 host1 --format yaml
moose-inventory host addvar owner=russell
moose-inventory host addvar host1 owner=russell id=12345
moose-inventory host addvar host2 owner=caroline id=54321
moose-inventory host list --format yaml
moose-inventory group add group1 group2 group3
moose-inventory group list --format yaml
moose-inventory group get ungrouped group3 --format yaml
moose-inventory group addvar location=usa
moose-inventory group addvar group1 location=usa
moose-inventory group addhost group1 host1 host2 
moose-inventory host addgroup host3 group2 group3 
moose-inventory group list --format yaml
moose-inventory host list --format yaml
moose-inventory group rmvar group1 location
moose-inventory group list --format y
moose-inventory group rm group1 group2 group3
moose-inventory host rmvar host1 owner id
moose-inventory host rm host1 host2 host3
moose-inventory host list
moose-inventory group list
