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

# Dependencies
sudo yum install java-1.8.0-openjdk.x86_64 -y
sudo yum install https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/rpm/elasticsearch/2.4.2/elasticsearch-2.4.2.rpm -y

# Configure Elasticsearch
sudo bash -c 'cat > /etc/elasticsearch/elasticsearch.yml <<EOF
network.host: 127.0.0.1
script.inline: on
cluster.name: hive
threadpool.index.queue_size: 100000
threadpool.search.queue_size: 100000
threadpool.bulk.queue_size: 1000
EOF'

# Install TheHive Project
sudo yum install https://dl.bintray.com/cert-bdf/rpm/thehive-project-release-1.0.0-3.noarch.rpm -y
sudo yum install thehive -y

# Configure TheHive Project for basic usage
(cat << _EOF_
play.crypto.secret="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)"
_EOF_
) | sudo tee -a /etc/thehive/application.conf

# Make firewall changes to allow for access to TheHive Project web application
sudo firewall-cmd --add-port=9000/tcp --permanent
sudo firewall-cmd --reload

# Ensure that thehive user owns it's directories
sudo chown -R thehive:thehive /opt/thehive
sudo chown thehive:thehive /etc/thehive/application.conf
sudo chmod 640 /etc/thehive/application.conf

# Set Elasticsearch and TheHive Project to start on boot
sudo systemctl enable elasticsearch.service
sudo systemctl enable thehive.service
sudo systemctl start elasticsearch.service
sudo systemctl start thehive.service

# Success
clear
cat << "EOF"
               `          `
             ``   `    `   ``
            ``     ````     ``
           ``      ....      ``
           ``       ``       ``
            ``   ```  ```   ``
              ``..` `` `..``
             `...` ```` `...`
            .....        .....
            ````  ``````  ````
                  ``````
                   ````
EOF
echo "TheHive has been successfully deployed. Browse to http://$HOSTNAME:9000 (or http://$IP:9001 if you don't have DNS set up) to begin using the service."
