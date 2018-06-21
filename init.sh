#!/bin/bash
echo "console-setup   console-setup/charmap47 select  UTF-8" > encoding.conf
debconf-set-selections encoding.conf
rm encoding.conf
export TERM=xterm
export DEBIAN_FRONTEND=noninteractive
echo "Updating package lists..."
apt-get -qq update
echo "Upgrading existing installed packages..."
apt-get -qq upgrade -y
echo "Installing required programs/libraries..."
apt-get -qq install awscli apache2 mysql-client php libapache2-mod-php php-mcrypt php-mysql php-curl php-mbstring php-gd php-xml php-xmlrpc php-zip -y
# pip install awscli --upgrade
echo "<?php phpinfo(); ?>" > /var/www/html/index.php
systemctl enable apache2
echo "*** init.sh execution complete ***" | wall
