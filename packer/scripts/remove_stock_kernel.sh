#!/bin/bash
set -eux 
apt-get -y remove linux-image-3.2.0-4-amd64
update-grub
