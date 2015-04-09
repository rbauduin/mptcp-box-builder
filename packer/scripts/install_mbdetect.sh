#!/bin/bash
set -eux
apt-get -y install libconfig9 libconfig-dev uuid-dev libc-ares-dev libcurl4-openssl-dev stow build-essential git curl ca-certificates
curl https://download.libsodium.org/libsodium/releases/LATEST.tar.gz  > /tmp/libsodium.tar.gz
cd /tmp	
tar zxf libsodium.tar.gz
cd libsodium-*
./configure --prefix=/usr/local/stow/libsodium
make
make install # possibly with sudo
cd /usr/local/stow
stow libsodium
ldconfig

cd /usr/local
git clone https://github.com/rbauduin/mbdetect.git
#cd mbdetect
#make client
#cp client /usr/local/bin/client
curl http://www.multipath-tcp.org/mbdetect/client > /usr/local/bin/client
chmod +x /usr/local/bin/client

mv /tmp/update-mbdetect.sh /usr/local/bin/update-mbdetect.sh
chmod +x /usr/local/bin/update-mbdetect.sh

mv /tmp/compile-mbdetect.sh /usr/local/bin/compile-mbdetect.sh
chmod +x /usr/local/bin/compile-mbdetect.sh
