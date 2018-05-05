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

# Create your Gitea passphrase
clear
echo "Create your Gitea passphrase for the MySQL database and press [Enter]. You will create your Gitea administration credentials after the installation."
read -s giteapassphrase

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
########## Gitea ###############
################################

# Install dependencies
sudo yum install epel-release -y
sudo yum install mariadb-server http://opensource.wandisco.com/centos/7/git/x86_64/wandisco-git-release-7-2.noarch.rpm firewalld -y
sudo yum update git -y
sudo systemctl start mariadb.service

# Configure MariaDB
mysql -u root -e "CREATE DATABASE gitea;"
mysql -u root -e "GRANT ALL PRIVILEGES ON gitea.* TO 'gitea'@'localhost' IDENTIFIED BY '$giteapassphrase';"
mysql -u root -e "FLUSH PRIVILEGES;"
mysql -u root -e "set global innodb_file_format = Barracuda;
set global innodb_file_per_table = on;
set global innodb_large_prefix = 1;
use gitea;
CREATE TABLE oauth2_session (
  id varchar(400) NOT NULL,
  data text,
  created_unix bigint(20) DEFAULT NULL,
  updated_unix bigint(20) DEFAULT NULL,
  expires_unix bigint(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
ALTER TABLE oauth2_session
  ADD PRIMARY KEY (id(191));
COMMIT;"

# Prevent remote access to MariaDB
sudo sh -c 'echo [mysqld] > /etc/my.cnf.d/bind-address.cnf'
sudo sh -c 'echo bind-address=127.0.0.1 >> /etc/my.cnf.d/bind-address.cnf'
sudo systemctl restart mariadb.service

# Create the Gitea user
sudo useradd -s /usr/sbin/nologin gitea

# Grab Gitea and make it a home
sudo mkdir -p /opt/gitea
sudo curl -o /opt/gitea/gitea https://dl.gitea.io/gitea/master/gitea-master-linux-amd64
sudo chown -R gitea:gitea /opt/gitea
sudo chmod 744 /opt/gitea/gitea

# Configure the firewall
# Port 4000 - Gitea
sudo firewall-cmd --add-port=4000/tcp --permanent
sudo firewall-cmd --reload

# Create the Gitea service
sudo bash -c 'cat > /etc/systemd/system/gitea.service <<EOF
[Unit]
Description=Gitea (Git with a cup of tea)
After=syslog.target
After=network.target
After=mariadb.service

[Service]
# Modify these two values and uncomment them if you have
# repos with lots of files and get an HTTP error 500 because
# of that
###
#LimitMEMLOCK=infinity
#LimitNOFILE=65535
RestartSec=2s
Type=simple
User=gitea
Group=gitea
WorkingDirectory=/opt/gitea
ExecStart=/opt/gitea/gitea web -p 4000
Restart=always
Environment=USER=gitea HOME=/home/gitea

[Install]
WantedBy=multi-user.target
EOF'

# Prepare the service environment
sudo systemctl daemon-reload

# Configure services for autostart
sudo systemctl enable mariadb.service
sudo systemctl enable gitea.service

# Secure MySQL installtion
mysql_secure_installation

# Start Gitea
sudo systemctl start gitea.service

###############################
### Clear your Bash history ###
###############################
# We don't want anyone snooping around and seeing any passphrases you set
cat /dev/null > ~/.bash_history && history -c

# Success page
clear
echo "The Gitea passphrase for the MySQL database is: "$giteapassphrase
echo "Gitea has been successfully deployed. Browse to http://$HOSTNAME:4000 (or http://$IP:4000 if you don't have DNS set up) to begin using the services."
echo "See the "Build, Operate, Maintain" document of the capesstack/capes/gitea repository on GitHub."
