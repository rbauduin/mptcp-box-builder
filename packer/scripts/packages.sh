#!/bin/bash
set -eux 
PACKAGES="
acpid
apt-file
bind9-host
bzip2
curl
dnsutils
emacs24-nox
git
htop
iproute
linux-mptcp
nmon
ntp
rsync
slurm
sudo
tcpdump
unzip
vim-nox
"
aptitude -y install --without-recommends $PACKAGES
#reboot
