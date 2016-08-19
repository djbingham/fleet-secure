#! /usr/bin/env bash

echo "Installing SSH key."

eval $(ssh-agent)
ssh-keygen -t rsa -f /home/core/.ssh/id_rsa -N ''
cat /home/core/.ssh/id_rsa.pub >> /home/core/.ssh/authorized_keys
ssh-keyscan localhost >> /home/core/.ssh/known_hosts
chown -R core:core /home/core/.ssh
