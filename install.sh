#!/bin/bash
set -e
########################################################
# wTorrent Installer 2009 November 08 Version 3.1 #
########################################################
# Author: Devin (devudio@gmail.com)
# Description: Automatically downloads and configures rTorrent and the wTorrent or ruTorrent web interface.
# rTorrent: http://libtorrent.rakshasa.no/
# wTorrent: http://www.wtorrent-project.org/
# ruTorrent: http://code.google.com/p/rutorrent/
########################################################
# This script and the configuration files are a combination of the information posted on these guides:
# http://www.wtorrent-project.org/trac/wiki/DebianInstall/
# http://robert.penz.name/82/howto-install-rtorrent-and-wtorrent-within-an-ubuntu-hardy-ve/
# http://flipsidereality.com/blog/linux/rtorrent-with-wtorrent-on-debian-etch-complete-howto/
########################################################

function fail {
	echo "$1" 1>&2
	echo "If you are trying to re-install rTorrent/wTorrent, run uninstall.sh first."
	exit 1
}
#Check if command line arguments are entered
if [ $1 ];
  then

# Copy the lighttpd configuration file and restart the server
echo "Copying lighttpd configuration file..."
sudo cp lighttpd.conf /etc/lighttpd/ || fail "Failed to copy lighttpd.conf.Does it exist in the current directory?"
echo "DONE"
echo "Restarting lighttpd..."
sudo /etc/init.d/lighttpd restart || fail "Failed to restart lighttpd. Please check /etc/lighttpd/lighttpd.conf."
echo "DONE"

#Switch statement to install specified webUI
#Currently only wTorrent and ruTorrent are supported
#TODO:
# Automatically create .htaccess file for ruTorrent to prevent unauthorized access
# Compile rTorrent with xmlrpc-c 1.11 to remove the error from ruTorrent.
case $1 in
wTorrent)
	# Download the latest wTorrent release
	echo "Downloading wTorrent..."
	sudo svn co -q svn://wtorrent-project.org/repos/trunk/wtorrent/ /var/www/ || fail "Failed to check out the latest wTorrent release from 'svn://wtorrent-project.org/repos/trunk/wtorrent/'. You can download it manually to '/var/www/'."
	sudo touch /var/www/db/database.db
	sudo chown -R www-data:www-data /var/www/db/ /var/www/torrents/ /var/www/tpl_c/
	sudo chmod 777 -R /var/www/conf/
	sudo sed -e 's:{$web->getOption('\''dir_download'\'')}:/home/rt/torrents/doing:' -i /var/www/wt/tpl/install/index.tpl.php || fail "Failed to set the default torrent data directory to '/home/rt/torrents/doing'. You can manually set it when you run install.php."
	echo "DONE"

	echo "rTorrent and wTorrent have been installed. Visit http://your.servers.ip.address/install.php to complete the configuration."
	;;
ruTorrent)
	# Download the latest rTorrent release
	echo "Downloading ruTorrent..."
	sudo svn co -q http://rutorrent.googlecode.com/svn/trunk/rtorrent/ /var/www/ || fail "Failed to check out the latest ruTorrent release from 'http://rutorrent.googlecode.com/svn/trunk/rtorrent/'. You can download it manually to '/var/www/'."
	sudo chmod 777 -R settings/ torrents/
	sudo rm -r rtorrent
	echo "DONE"

	echo "rTorrent and ruTorrent have been installed. Visit http://your.servers.ip.address/ and edit your settings to complete the configuration."
	echo " Additionally, you may wish to prevent unauthorized access to ruTorrent by editing lighttpd's configuration file or other methods to provide authentication."
	;;
*)
	echo "Please enter a command line argument corresponding to the webUI you wish to install: "
	echo "./install.sh wTorrent"
	echo "./install.sh ruTorrent"
;;
esac

#Switch statement to install rTorrent from specified source
#Either aptitude or subversion
case $2 in
apt)
	# Install rTorrent and required packages from aptitude
	echo "Installing rTorrent and required packages..."
	sudo apt-get -y install rtorrent screen mc lighttpd gawk php5-cgi php5-common php5-sqlite php5-xmlrpc php5-curl sqlite subversion
	echo "DONE"
	
	
	# Add rt user to run the rTorrent process
	echo "Adding rt user to run the rTorrent process..."
	sudo adduser -q --disabled-login --gecos rt rt || fail "Failed to create the 'rt' user."
	sudo usermod -aG tty rt
	echo "DONE"

	# Copy the rTorrent configuration file and create folders for downloading torrents to
	echo "Copying rTorrent configuration file and creating folders..."
	sudo cp .rtorrent.rc /home/rt/ || fail "Failed to copy .rtorrent.rc. Does it exist in the current directory?"
	sudo mkdir -p /home/rt/torrents/watch/ /home/rt/torrents/doing/ /home/rt/torrents/done/ /home/rt/.rtsession/ || fail "Failed to create /home/rt/torrents and sub directories."
	sudo chown -R rt.rt /home/rt/ || fail "Failed to set proper ownership of /home/rt/."
	echo "DONE"

	# Copy and start the rTorrent INIT script
	echo "Copying rTorrent INIT script..."
	sudo cp rtorrent /etc/init.d/rtorrent || fail "Failed to copy the rTorrrent INIT script. Does it exist in the current directory?"
	sudo update-rc.d rtorrent defaults 25 || fail "Failed to add rTorrrent system startup links. Is the INIT script already configured?"
	echo "DONE"
	sudo /etc/init.d/rtorrent start
	;;
svn)
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
	
	
	# Add rt user to run the rTorrent process
	echo "Adding rt user to run the rTorrent process..."
	sudo adduser -q --disabled-login --gecos rt rt || fail "Failed to create the 'rt' user."
	sudo usermod -aG tty rt
	echo "DONE"

	# Copy the rTorrent configuration file and create folders for downloading torrents to
	echo "Copying rTorrent configuration file and creating folders..."
	sudo cp .rtorrent.rc /home/rt/ || fail "Failed to copy .rtorrent.rc. Does it exist in the current directory?"
	sudo mkdir -p /home/rt/torrents/watch/ /home/rt/torrents/doing/ /home/rt/torrents/done/ /home/rt/.rtsession/ || fail "Failed to create /home/rt/torrents and sub directories."
	sudo chown -R rt.rt /home/rt/ || fail "Failed to set proper ownership of /home/rt/."
	echo "DONE"

	# Copy and start the rTorrent INIT script
	echo "Copying rTorrent INIT script..."
	sudo cp rtorrent /etc/init.d/rtorrent || fail "Failed to copy the rTorrrent INIT script. Does it exist in the current directory?"
	sudo update-rc.d rtorrent defaults 25 || fail "Failed to add rTorrrent system startup links. Is the INIT script already configured?"
	echo "DONE"
	sudo /etc/init.d/rtorrent start
	;;
*)
	echo "No source was specified, so rTorrent was not installed. If you'd like to install rTorrent, run the script and specify either aptitude or subversion like this: "
	echo "./install.sh [webui] apt"
	echo "./install.sh [webui] svn"
;;
esac
	
  #Throw eror if no argument is provided
  else 
  echo "Please provide the name of the WebUI you wish to install as an argument"
  fi
exit 0
