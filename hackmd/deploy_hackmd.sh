#!/bin/bash

################################
######### Epel Release #########
################################
# The DISA STIG for CentOS 7.4.1708 enforces a GPG signature check for all repodata. While this is generally a good idea, it causes repos tha do not use GPG Armor to fail.
# One example of a repo that does not use GPG Armor is Epel; which is a dependency of CAPES (and tons of other projects, for that matter).
# To fix this, we are going to disable the GPG signature and local RPM GPG signature checking.
# I'm open to other options here.
# RHEL's official statement on this: https://access.redhat.com/solutions/2850911
sudo sed -i 's/repo_gpgcheck=1/repo_gpgcheck=0/' /etc/yum.conf
sudo sed -i 's/localpkg_gpgcheck=1/localpkg_gpgcheck=0/' /etc/yum.conf

################################
##### Collect Credentials ######
################################

# Create your HackMD passphrase
echo "Create your HackMD passphrase for the MySQL database and press [Enter]. You will create your specific HackMD credentials after the installation."
read -s hackmdpassphrase

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
############ HackMD ############
################################

# Install dependencies
sudo yum install epel-release -y
sudo yum install mariadb-server npm gcc-c++ git bzip2 -y

# Stage HackMD for building
sudo npm install -g uws node-gyp tap webpack grunt yarn
sudo yarn add -D webpack-cli
sudo git clone https://github.com/hackmdio/hackmd.git /opt/hackmd/
cd /opt/hackmd
sudo bin/setup
cd -

# Set up the HackMD database
sudo systemctl start mariadb.service
mysql -u root -e "CREATE DATABASE hackmd;"
mysql -u root -e "GRANT ALL PRIVILEGES ON hackmd.* TO 'hackmd'@'localhost' IDENTIFIED BY '$hackmdpassphrase';"

# Update the HackMD configuration files
sudo sed -i 's/"username":\ ""/"username":\ "hackmd"/' /opt/hackmd/config.json
sudo sed -i 's/"password":\ ""/"password":\ "'$hackmdpassphrase'"/' /opt/hackmd/config.json
sudo sed -i 's/5432/3306/' /opt/hackmd/config.json
sudo sed -i 's/postgres/mysql/' /opt/hackmd/config.json
sudo sed -i 's/change\ this/mysql:\/\/hackmd:'$hackmdpassphrase'@localhost:3306\/hackmd/' /opt/hackmd/.sequelizerc

# Build HackMD
sudo npm run build --prefix /opt/hackmd/

# Add the HackMD user with no login
sudo useradd -s /usr/sbin/nologin hackmd

# Set directory permissions for HackMD
sudo chown -R hackmd:hackmd /opt/hackmd

# Creating the HackMD service
sudo bash -c 'cat > /etc/systemd/system/hackmd.service <<EOF
[Unit]
Description=HackMD Service
Requires=network-online.target
After=network-online.target mariadb.service time-sync.target

[Service]
User=hackmd
Group=hackmd
WorkingDirectory=/opt/hackmd
Type=simple
ExecStart=/bin/npm start production --prefix /opt/hackmd/

[Install]
WantedBy=multi-user.target
EOF'

# Prepare the service environment
sudo systemctl daemon-reload

# Configure HackMD services
sudo systemctl enable mariadb.service
sudo systemctl enable hackmd.service

# Configure the firewall
sudo firewall-cmd --add-port=3000/tcp --permanent
sudo firewall-cmd --reload

# Remove gcc
sudo yum -y remove gcc-c++

################################
### Secure MySQL installtion ###
################################
clear
echo "In a few seconds we are going to secure your MariaDB configuration. You'll be asked for your MariaDB root passphrase (which hasn't been set), you'll set the MariaDB root passphrase and then be asked to confirm some security configurations."
sudo sh -c 'echo [mysqld] > /etc/my.cnf.d/bind-address.cnf'
sudo sh -c 'echo bind-address=127.0.0.1 >> /etc/my.cnf.d/bind-address.cnf'
sudo systemctl restart mariadb.service
mysql_secure_installation

###############################
### Clear your Bash history ###
###############################
# We don't want anyone snooping around and seeing any passphrases you set
cat /dev/null > ~/.bash_history && history -c

# Start HackMD service
sudo systemctl start hackmd.service
clear
echo "HackMD has been successfully deployed. Browse to http://$HOSTNAME:3000 (or http://$IP:3000 if you don't have DNS set up) to begin using the service."
echo "See the "Build, Operate, Maintain" document of the capesstack/capes/hackmd repository on GitHub."
