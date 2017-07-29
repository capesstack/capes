#!/bin/bash

# Set your IP address as a variable. This is for instructions below.
IP="$(hostname -I | sed -e 's/[[:space:]]*$//')"

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
sudo curl -L https://rocket.chat/releases/latest/download -o /opt/rocketchat/rocket.chat.tgz
echo "This next part takes a few minutes, everything is okay...go have a scone."
sudo tar zxf /opt/rocketchat/rocket.chat.tgz -C /opt/rocketchat/
sudo mv /opt/rocketchat/bundle /opt/rocketchat/Rocket.Chat
cd /opt/rocketchat/Rocket.Chat/programs/server
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

# Configure RocketChat services
sudo systemctl enable mongod.service
sudo systemctl enable rocketchat.service

# Configure the firewall
sudo firewall-cmd --add-port=3000/tcp --permanent
sudo firewall-cmd --reload

# Start RocketChat and MongoDB services
sudo systemctl start mongod.service
sudo systemctl start rocketchat.service
clear
cat << "EOF"


.:+ossyysss+/-.
`+yyyyyyyyyyyyys/.
  .oyyyyyyyyyyyyyyo++oossssoo++/:-.`
    +yyyyyyyyyyyyyyyyyssssssyyyyyyyys+:.
     syyyyyyyyo+:-.`         ``.-:+oyyyys+-
    `oyyyyo:.                        .:oyyys/`
   -syys/`                              `/syys-
  /yyy/                                    /yyy/
 :yyy-                                      -yyy:
 yyy/        ./+/.     :++:     ./+/.        /yyy
`yyy-       .yyyyy`   +yyyy+   `yyyyy.       -yyy`
 syy/        +yyy+    -syys-    +yyy+        /yys
 :yyy-         `        ``        `         :yyy:
  /yyy/                                   .+yyy/
   -syys/                              `-+syys-
     oyyy`                       ``..:+syyys:
     syyo       .:::-........-::/+osyyyys+-
    +yys.   `..:oyyyyyssssssyyyyyyyys+:.
  .syys-..--:+syyyo++ooossooo++/:-.
.+yyyy+++ooyyyys/.
.:+osssssso+/-`
EOF
echo "Rocketchat has been successfully deployed. Browse to http://$HOSTNAME:3000 (or http://$IP:3000 if you don't have DNS set up) to begin using the service."
