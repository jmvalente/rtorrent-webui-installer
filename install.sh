#!/bin/bash
set -e
########################################################
# wTorrent Installer 2009 February 21 Version 2.1 #
########################################################
# Author: Devin (devudio@gmail.com)
# Description: Automatically downloads and configures rTorrent and the wTorrent web interface.
# rTorrent: http://libtorrent.rakshasa.no/
# wTorrent: http://www.wtorrent-project.org/
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

# Install rTorrent and required packages
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
	cd /var/www
	sudo svn co -q svn://wtorrent-project.org/repos/trunk/wtorrent/ || fail "Failed to check out the latest wTorrent release from 'svn://wtorrent-project.org/repos/trunk/wtorrent/'. You can download it manually to '/var/www/'."
	cd wtorrent
	sudo mv * .. || fail "Failed to move wTorrent files to /var/www/. Please remove any wTorrent files and directories from /var/www/ before running the script."
	cd ..
	sudo rm -r wtorrent
	sudo touch ./db/database.db
	sudo chown -R www-data:www-data db torrents tpl_c
	sudo chmod 777 -R conf/
	sudo sed -e 's:{$web->getOption('\''dir_download'\'')}:/home/rt/torrents/doing:' -i wt/tpl/install/index.tpl.php || fail "Failed to set the default torrent data directory to '/home/rt/torrents/doing'. You can manually set it when you run install.php."
	echo "DONE"

	echo "rTorrent and wTorrent have been installed. Visit http://your.servers.ip.address/install.php to complete the configuration."
	;;
ruTorrent)
	# Download the latest wTorrent release
	echo "Downloading ruTorrent..."
	cd /var/www
	svn co -q http://rutorrent.googlecode.com/svn/trunk/rtorrent/ || fail "Failed to check out the latest ruTorrent release from 'http://rutorrent.googlecode.com/svn/trunk/rtorrent/'. You can download it manually to '/var/www/'."
	cd rtorrent
	sudo mv * .. || fail "Failed to move ruTorrent files to /var/www/. Please remove any ruTorrent files and directories from /var/www/ before running the script."
	cd ..
	sudo chmod 777 -R settings/ torrents/
	sudo rm -r rtorrent
	echo "DONE"

	echo "rTorrent and ruTorrent have been installed. Visit http://your.servers.ip.address/ and edit your settings to complete the configuration."
	echo "Additionally, you may wish to create an .htaccess file to prevent unauthorized access"
	;;
*)
	echo "Please enter a command line argument corresponding to the webUI you wish to install: "
	echo "./install.sh wTorrent"
	echo "./install.sh ruTorrent"
;;
esac
exit 0
