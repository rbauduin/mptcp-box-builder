#!/bin/bash 

# install tcpudump
apt-get install -y tcpdump libcap2-bin tmux lftp

# make is runnable by vagrant without super user provilege
groupadd tcpdump
addgroup vagrant tcpdump
chown root.tcpdump /usr/sbin/tcpdump
chmod 0750 /usr/sbin/tcpdump
setcap "CAP_NET_RAW+eip" /usr/sbin/tcpdump
