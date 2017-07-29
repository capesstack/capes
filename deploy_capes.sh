#!/bin/bash

################################
##### Collect Credentials ######
################################
# Create your GoGS password
echo "Set your GoGS password and press [Enter]"
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
########## RocketChat ##########
################################

# Configure MongoDB Yum repository
sudo bash -c 'cat > /etc/yum.repos.d/mongodb.repo <<EOF
[mongodb-org-3.4]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/7/mongodb-org/3.4/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-3.4.asc
EOF'

# Install dependencies
sudo yum install epel-release -y && sudo yum update -y
sudo yum install nodejs curl GraphicsMagick npm mongodb-org gcc-c++ nginx -y

# Configure npm
sudo npm install -g inherits n
sudo n 4.5

# Build RocketChat
sudo mkdir /opt/rocketchat
curl -L https://rocket.chat/releases/latest/download -o rocketchat.tar.gz
echo "This next part takes a few minutes, everything is okay...go have a scone."
sudo tar zxf rocketchat.tar.gz -C /opt/rocketchat/
sudo mv /opt/rocketchat/bundle /opt/rocketchat/Rocket.Chat
rm rocketchat.tar.gz
# cd /opt/rocketchat/Rocket.Chat/programs/server
sudo npm --prefix /opt/rocketchat/Rocket.Chat/programs/server install

# Add the RocketChat user with no login
sudo useradd -s /usr/sbin/nologin rocketchat

# Set directory permissions for RocketChat
sudo chown -R rocketchat:rocketchat /opt/rocketchat

# Create the Rocketchat service
sudo bash -c 'cat > /usr/lib/systemd/system/rocketchat.service <<EOF
[Unit]
Description=The Rocket.Chat server
After=network.target remote-fs.target nss-lookup.target nginx.target mongod.target
[Service]
ExecStart=/usr/local/bin/node /opt/rocketchat/Rocket.Chat/main.js
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=rocketchat
User=rocketchat
Environment=MONGO_URL=mongodb://localhost:27017/rocketchat ROOT_URL=http://localhost:3000/ PORT=3000
[Install]
WantedBy=multi-user.target
EOF'

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

# Secure MySQL
sudo sh -c 'echo [mysqld] > /etc/my.cnf.d/bind-address.cnf'
sudo sh -c 'echo bind-address=127.0.0.1 >> /etc/my.cnf.d/bind-address.cnf'
sudo systemctl restart mariadb.service

# Add the GoGS user with no login
sudo useradd -s /usr/sbin/nologin git

# Build GoGS
sudo mkdir /opt/gogs
curl -L https://dl.gogs.io/0.11.19/linux_amd64.zip -o gogs.zip
sudo unzip gogs.zip -d /opt/
rm gogs.zip

# Set directory permissions for GoGS
sudo chown -R git:git /opt/gogs

sudo bash -c 'cat > /usr/lib/systemd/system/gogs.service <<EOF
[Unit]
Description=GoGS
After=syslog.target network.target mariadb.service
[Service]
Type=simple
User=git
Group=git
WorkingDirectory=/opt/gogs/
ExecStart=/opt/gogs/gogs web -port 4000
Restart=always
Environment=USER=git HOME=/home/git
[Install]
WantedBy=multi-user.target
EOF'

################################
############ Nginx #############
################################

# Update the landing page index file
sed -i "s/your-hostname/$HOSTNAME/" landing_page/index.html

# Move landing page framework into Nginx's working directory
sudo cp -r landing_page/* /usr/share/nginx/html/

# Configure the firewall
# Port 80 - Nginx
# Port 3000 - RocketChat
# Port 4000 - GoGS
# Port 5000 - Etherpad
# Port 6000 - MISP
# Port 7000 - CyberChef
# Port 9000 - TheHive
# Port 9001 - Cortex (TheHive Analyzer Plugins)
# Port 9002 - HippoCampe (TheHive Threat Feed Plugin)
sudo firewall-cmd --add-port=80/tcp --add-port=3000/tcp --add-port=4000/tcp --permanent
sudo firewall-cmd --reload

# Configure services for autostart
sudo systemctl enable nginx.service
sudo systemctl enable mariadb.service
sudo systemctl enable mongod.service
sudo systemctl enable rocketchat.service

# Start all the services
sudo systemctl start mongod.service
sudo systemctl start rocketchat.service
sudo systemctl start gogs.service
sudo systemctl start nginx.service

# Secure MySQL installtion
# mysql_secure_installation

# Success page
clear
echo "The CAPES landing page has been successfully deployed. Browse to http://$HOSTNAME (or http://$IP if you don't have DNS set up) to begin using the services."
