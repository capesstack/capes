#!/bin/bash

################################
##### Collect Credentials ######
################################

# Create your GoGS password
echo "Create your GoGS password for the MySQL database and press [Enter]. You will create your GoGS administration credentials after the installation."
read -s gogspassword

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
sudo yum install -y mariadb-server git unzip
sudo systemctl start mariadb.service

# Configure MySQL
mysql -u root -e "CREATE DATABASE gogs;"
mysql -u root -e "GRANT ALL PRIVILEGES ON gogs.* TO 'gogs'@'localhost' IDENTIFIED BY '$gogspassword';"
mysql -u root -e "FLUSH PRIVILEGES;"

# Prevent remote access to MySQL
sudo sh -c 'echo [mysqld] > /etc/my.cnf.d/bind-address.cnf'
sudo sh -c 'echo bind-address=127.0.0.1 >> /etc/my.cnf.d/bind-address.cnf'
sudo systemctl restart mariadb.service

# Add the GoGS user with no login
sudo useradd -s /usr/sbin/nologin gogs

# Build GoGS
sudo mkdir /opt/gogs
curl -L https://dl.gogs.io/0.11.19/linux_amd64.zip -o gogs.zip
sudo unzip gogs.zip -d /opt/
rm gogs.zip

# Set directory permissions for GoGS
sudo chown -R gogs:gogs /opt/gogs

sudo bash -c 'cat > /usr/lib/systemd/system/gogs.service <<EOF
[Unit]
Description=GoGS
After=syslog.target network.target mariadb.service
[Service]
Type=simple
User=gogs
Group=gogs
WorkingDirectory=/opt/gogs/
ExecStart=/opt/gogs/gogs web -port 4000
Restart=always
Environment=USER=gogs HOME=/home/gogs
[Install]
WantedBy=multi-user.target
EOF'

# Configure the firewall
# Port 4000 - GoGS
sudo firewall-cmd --add-port=4000/tcp --permanent
sudo firewall-cmd --reload

# Configure services for autostart
sudo systemctl enable mariadb.service
sudo systemctl enable gogs.service

# Start all the services
sudo systemctl start gogs.service

# Secure MySQL installtion
mysql_secure_installation

# Success page
clear
echo "GoGS has been successfully deployed. Browse to http://$HOSTNAME:4000 (or http://$IP:4000 if you don't have DNS set up) to begin using the services."
