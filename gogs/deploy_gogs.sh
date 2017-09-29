#!/bin/bash

################################
##### Collect Credentials ######
################################

# Create your GoGS passphrase
clear
echo "Create your GoGS passphrase for the MySQL database and press [Enter]. You will create your GoGS administration credentials after the installation."
read -s gogspassphrase

# Set your IP address as a variable. This is for instructions below.
IP="$(hostname -I | sed -e 's/[[:space:]]*$//')"

################################
######## Configure NTP #########
################################

# Set your time to UTC, this is crucial. If you have already set your time in accordance with your local standards, you may comment this out.
# If you're not using UTC, I strongly recommend reading this: http://yellerapp.com/posts/2015-01-12-the-worst-server-setup-you-can-make.html
sudo timedatectl set-timezone UTC

# Set NTP. If you have already set your NTP in accordance with your local standards, you may comment this out.
sudo bash -c 'cat > /etc/chrony.conf <<EOF
# Use public servers from the pool.ntp.org project.
# Please consider joining the pool (http://www.pool.ntp.org/join.html).
server 0.centos.pool.ntp.org iburst
server 1.centos.pool.ntp.org iburst
server 2.centos.pool.ntp.org iburst
server 3.centos.pool.ntp.org iburst

# Ignore stratum in source selection.
stratumweight 0

# Record the rate at which the system clock gains/losses time.
driftfile /var/lib/chrony/drift

# Enable kernel RTC synchronization.
rtcsync

# In first three updates step the system clock instead of slew
# if the adjustment is larger than 10 seconds.
makestep 10 3

# Allow NTP client access from local network.
#allow 192.168/16

# Listen for commands only on localhost.
bindcmdaddress 127.0.0.1
bindcmdaddress ::1

# Serve time even if not synchronized to any NTP server.
#local stratum 10

keyfile /etc/chrony.keys

# Specify the key used as password for chronyc.
commandkey 1

# Generate command key if missing.
generatecommandkey

# Disable logging of client accesses.
noclientlog

# Send a message to syslog if a clock adjustment is larger than 0.5 seconds.
logchange 0.5

logdir /var/log/chrony
#log measurements statistics tracking
EOF'
sudo systemctl enable chronyd.service
sudo systemctl start chronyd.service

################################
############# GoGS #############
################################

# Install dependencies
sudo yum install mariadb-server -y
sudo systemctl start mariadb.service

# Configure MySQL
mysql -u root -e "CREATE DATABASE gogs;"
mysql -u root -e "GRANT ALL PRIVILEGES ON gogs.* TO 'gogs'@'localhost' IDENTIFIED BY '$gogspassphrase';"
mysql -u root -e "FLUSH PRIVILEGES;"

# Prevent remote access to MySQL
sudo sh -c 'echo [mysqld] > /etc/my.cnf.d/bind-address.cnf'
sudo sh -c 'echo bind-address=127.0.0.1 >> /etc/my.cnf.d/bind-address.cnf'
sudo systemctl restart mariadb.service

# Build GoGS
sudo curl -L https://dl.packager.io/srv/pkgr/gogs/pkgr/installer/el/7.repo -o /etc/yum.repos.d/gogs.repo
sudo yum install -y gogs

# Change the GoGS user to not have a login
sudo usermod -s /usr/sbin/nologin gogs

# Change the default GoGS port
sudo systemctl stop gogs-web-1.service gogs.service
sudo sed -i 's/6000/4000/' /etc/systemd/system/gogs-web-1.service
sudo systemctl daemon-reload
sudo systemctl start gogs-web-1.service gogs.service

# Configure the firewall
# Port 4000 - GoGS
sudo firewall-cmd --add-port=4000/tcp --permanent
sudo firewall-cmd --reload

# Configure services for autostart
sudo systemctl enable mariadb.service

# Secure MySQL installtion
mysql_secure_installation

###############################
### Clear your Bash history ###
###############################
cat /dev/null > ~/.bash_history && history -c

# Success page
clear
echo "The GoGS passphrase for the MySQL database is: "$gogspassphrase
echo "GoGS has been successfully deployed. Browse to http://$HOSTNAME:4000 (or http://$IP:4000 if you don't have DNS set up) to begin using the services."
echo "See the "Build, Operate, Maintain" document of the capesstack/capes/gogs repository on GitHub."
