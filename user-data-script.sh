#!/bin/bash -ex

#output details to /var/log/user-data.log
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

apt-get update

apt-get --yes install git puppet

# Fetch puppet configuration from public git repository and get sumodules
mv /etc/puppet /etc/puppet.orig
git clone https://github.com/Spearmint-Digital/mint-server-setup.git /etc/puppet
git submodule update --init

# Run puppet.
puppet apply /etc/puppet/manifests/default.pp

