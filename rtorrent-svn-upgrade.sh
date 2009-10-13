#!/bin/bash
set -e
########################################################
# rTorrent Upgrader 2009 June 10 Version 1.0 #
########################################################
# Author: Devin (devudio@gmail.com)
# Description: Automatically removes the rTorrent package installed from the repositories, and installs the latest rTorrent from SVN.
# rTorrent: http://libtorrent.rakshasa.no/
########################################################

function fail {
	echo "$1" 1>&2
	echo "If you are trying to re-install rTorrent/wTorrent, run uninstall.sh first."
	exit 1
}

# Remove rTorrent
sudo apt-get -y remove rtorrent libtorrent11 libxmlrpc-c3

# Install dependencies
sudo apt-get -y install autoconf automake autotools-dev binutils build-essential bzip2 ca-certificates comerr-dev cpp cpp-4.1 dpkg-dev file g++ g++-4.1 gawk gcc gcc-4.1 libapr1 libaprutil1 libc6-dev libexpat1 libidn11 libidn11-dev libkadm55 libkrb5-dev libmagic1 libncurses5-dev libneon26 libpcre3 libpq5 libsigc++-2.0-dev libsqlite0 libsqlite3-0 libssl-dev libssp0-dev libstdc++6-4.1-dev libsvn1 libtool libxml2 linux-libc-dev lynx m4 make mime-support ntp ntpdate openssl patch pkg-config ucf zlib1g-dev libcurl4-openssl-dev || fail "Failed to install dependencies."

# Download and install xmlrpc
cd
svn co https://xmlrpc-c.svn.sourceforge.net/svnroot/xmlrpc-c/stable xmlrpc-c || fail "Failed to check out the latest stable version of xmlrpc-c."
cd xmlrpc-c
sudo ./configure --disable-cplusplus || fail "Failed to configure xmlrpc-c."
sudo make || fail "Failed to make xmlrpc-c."
sudo make install || fail "Failed to install xmlrpc-c."

# Download and install rTorrent
cd
mkdir rtorrent-svn
cd rtorrent-svn
svn co svn://rakshasa.no/libtorrent/trunk || fail "Failed to check out the latest versions of libTorrent and rTorrent."
svn up
cd trunk/libtorrent/
sudo ./autogen.sh
sudo ./configure || fail "Failed to configure libtorrent."
sudo make || fail "Failed to make libtorrent."
sudo make install || fail "Failed to install libtorrent."
cd ../rtorrent
sudo ./autogen.sh
sudo ./configure --with-xmlrpc-c || fail "Failed to configure rtorrent."
sudo make || fail "Failed to make rtorrent."
sudo make install || fail "Failed to install rtorrent."