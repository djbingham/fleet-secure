#! /usr/bin/env bash

echo "Installing bash completion for Docker."

# Using toolbox to access utility functions on CoreOS
toolbox dnf update --verbose --assumeyes
toolbox dnf install --verbose --assumeyes bash-completion

toolbox curl --create-dirs -L https://raw.githubusercontent.com/docker/docker/v$(docker version -f '{{.Client.Version}}')/contrib/completion/bash/docker -o /usr/share/bash-completion/completions/docker

toolbox cp -R /usr/share/bash-completion/ /media/root/var/

source /var/bash-completion/bash_completion

echo 'source /var/bash-completion/bash_completion' >> /home/core/.bashrc
