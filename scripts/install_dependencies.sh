#!/bin/bash

sudo dnf groupinstall "C Development Tools and Libraries" "Development Tools"
sudo dnf install ansible \
            ruby \
            ruby-devel \
            rubygem-mysql2 \
            mysql-utilities \
            rubygem-sqlite3 \
            sqlite \
            sqlite-libs \
            sqlite-devel \
            mariadb-devel \
            mariadb \
            rubygem-bundler \
            libffi-devel \
            libffi \
            rubygem-ffi \
            rubygem-hitimes \
            rpm-build \
            postgresql \
            postgresql-devel

