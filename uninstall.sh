#!/bin/bash
########################################################
# rTorrent WebUI Uninstaller 2009 November 13 Version 1.1 #
########################################################
# Author: daymun (http://github.com/daymun)
# GitHub repository: http://github.com/daymun/rtorrent-webui-installer
# Description: Reverses any changes to the system made by install.sh.
########################################################

function fail {
	echo "$1" 1>&2
	echo -n "Continue anyway? [Y/n] "
	read continue
	if [ "$continue" = "n" ]; then
		exit 1
	fi
}

# Stop the rTorrent INIT script
echo "Stopping the rTorrent INIT script..."
sudo /etc/init.d/rtorrent stop || fail "Failed to stop the rTorrent INIT script."
echo "DONE"

# Remove the rTorrent INIT script
echo "Removing the rTorrent INIT script..."
sudo rm /etc/init.d/rtorrent || fail "Failed to remove the rTorrent INIT script."
sudo update-rc.d -f rtorrent remove || fail "Failed to remove rTorrent system startup links."
echo "DONE"

# Delete rt user and rt's home directory, including torrent data sub directories
echo "Deleting rt user and rt's home directory, including torrent data sub directories..."
sudo userdel -rf rt || fail "Failed to delete 'rt' user."
echo "DONE"

# Stop lighttpd
echo "Stopping lighttpd..."
sudo /etc/init.d/lighttpd stop || fail "Failed to stop lighttpd."
echo "DONE"

# Remove WebUI
echo "Removing wTorrent..."
sudo rm -rf /var/www/* || "Failed to remove WebUI."
sudo rm -rf /var/www/.svn/ || "Failed to remove WebUI's .svn directory."
echo "DONE"

# Ask the user if all packages should be removed
echo -n "THE FOLLOWING PACKAGES WILL NOW BE REMOVED: rtorrent screen mc lighttpd gawk php5-cgi php5-common php5-sqlite php5-xmlrpc php5-curl sqlite subversion. If you use this server for anything besides rTorrent/wTorrent, this could adversely affect your system, and you should consider skiping this step and removing any undesired packages manually. If you do not use this server for anything besides rTorrent/wTorrent, you can safely remove these packages. Continue removing said packages? [y/N] "
read verify
if [ "$verify" = "y" ]; then # User said yes, remove packages
	sudo dpkg --purge rtorrent screen mc lighttpd gawk php5-cgi php5-common php5-sqlite php5-xmlrpc php5-curl sqlite subversion || fail "Failed to remove rTorrent and required packages."
else # User did not say yes
	echo "No packages were removed."
fi
echo "Uninstallation has completed successfully."
exit 0
