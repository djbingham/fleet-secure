#! /usr/bin/bash

echo "Creating editable .bashrc file in place of default symbolic link."

cp /usr/share/skel/.bashrc /home/core/.bashrc.new
mv /home/core/.bashrc.new /home/core/.bashrc
