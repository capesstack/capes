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
sudo yum install java-1.8.0-openjdk.x86_64 epel-release -y
sudo yum groupinstall "Development Tools" -y
sudo yum install https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/rpm/elasticsearch/2.4.2/elasticsearch-2.4.2.rpm libffi-devel python-devel python-pip ssdeep-devel ssdeep-libs perl-Image-ExifTool file-devel -y

# Configure Elasticsearch
sudo bash -c 'cat > /etc/elasticsearch/elasticsearch.yml <<EOF
network.host: 127.0.0.1
script.inline: on
cluster.name: hive
threadpool.index.queue_size: 100000
threadpool.search.queue_size: 100000
threadpool.bulk.queue_size: 1000
EOF'

# Install TheHive Project and Cortex
# TheHive Project is the incident tracker, Cortex is your analysis engine.
# If you're going to be using this offline, you can comment out Cortex.
sudo yum install https://dl.bintray.com/cert-bdf/rpm/thehive-project-release-1.0.0-3.noarch.rpm -y
sudo yum install thehive cortex -y

# Configure TheHive Project for basic usage
(cat << _EOF_
play.crypto.secret="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)"
_EOF_
) | sudo tee -a /etc/thehive/application.conf

# Configure Cortex for basic usage
(cat << _EOF_
# Secret key
# ~~~~~
# The secret key is used to secure cryptographics functions.
# If you deploy your application to several instances be sure to use the same key!
play.crypto.secret="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)"
_EOF_
) | sudo tee -a /etc/cortex/application.conf

# Make firewall changes to allow for access to TheHive Project and Cortex web applications
sudo firewall-cmd --add-port=9000/tcp --add-port=9001/tcp --permanent
sudo firewall-cmd --reload

# Collect the Cortex analyzers
git clone https://github.com/CERT-BDF/Cortex-Analyzers.git
sudo mv Cortex-Analyzers/ /opt/cortex/

# Add the future Python package and then install the Cortex Python dependencies
for d in /opt/cortex/Cortex-Analyzers/analyzers/*/ ; do (cd "$d" && sudo echo "future" >> requirements.txt); done
for d in /opt/cortex/Cortex-Analyzers/analyzers/*/ ; do (cd "$d" && sudo pip install -r requirements.txt); done

# Need to update the location of the analyzers directory in /etc/cortex/applicatin.conf
https://unix.stackexchange.com/questions/159367/using-sed-to-find-and-replace

# Need to uncomment Cortex URL in /etc/thehive/application.conf and use $hostname:9001

# Ensure that thehive and cortex users owns it's directories
sudo chown -R thehive:thehive /opt/thehive
sudo chown thehive:thehive /etc/thehive/application.conf
sudo chmod 640 /etc/thehive/application.conf
sudo chown -R cortex:cortex /opt/cortex
sudo chown cortex:cortex /etc/cortex/application.conf
sudo chmod 640 /etc/cortex/application.conf

# Set Elasticsearch and TheHive Project to start on boot
sudo systemctl enable elasticsearch.service
sudo systemctl enable thehive.service
sudo systemctl enable cortex.service

# Configure Cortex to run on port 9001 instead of the default 9000, which is shared with TheHive
sudo sed -i '16i\\t-Dhttp.port=9001 \\' /etc/systemd/system/cortex.service

# Start all services
sudo systemctl start elasticsearch.service
sudo systemctl start thehive.service
sudo systemctl start cortex.service

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
echo "TheHive has been successfully deployed. Browse to http://$HOSTNAME:9000 (or http://$IP:9000 if you don't have DNS set up) to begin using the service."
