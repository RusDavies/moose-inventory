#!/bin/bash
set -euo pipefail

sudo dnf groupinstall -y "C Development Tools and Libraries" "Development Tools"
sudo dnf install -y \
            ansible \
            ruby \
            ruby-devel \
            rubygem-bundler \
            sqlite \
            sqlite-libs \
            sqlite-devel \
            mariadb-connector-c-devel \
            libpq-devel \
            libffi \
            libffi-devel \
            rpm-build
