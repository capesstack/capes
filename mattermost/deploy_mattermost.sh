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

clear
# Create your Mattermost passphrase
echo "Create your Mattermost passphrase for the MySQL database and press [Enter]. You will create your Mattermost administration credentials after the installation."
read -s mattermostpassphrase

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
########## Mattermost ##########
################################

# Install dependencies
sudo yum install epel-release mariadb-server firewalld -y

# Configure MariaDB
sudo systemctl start mariadb.service
mysql -u root -e "CREATE DATABASE mattermost;"
mysql -u root -e "GRANT ALL PRIVILEGES ON mattermost.* TO 'mattermost'@'localhost' IDENTIFIED BY '$mattermostpassphrase';"

# Build Mattermost
sudo mkdir -p /opt/mattermost/data
sudo curl -L https://releases.mattermost.com/4.9.2/mattermost-4.9.2-linux-amd64.tar.gz -o /opt/mattermost/mattermost.tar.gz
sudo tar -xzf /opt/mattermost/mattermost.tar.gz -C /opt/

# Add the Mattermost user with no login
sudo useradd -s /usr/sbin/nologin mattermost

# Set directory permissions for Mattermost
sudo chown -R mattermost:mattermost /opt/mattermost
sudo chmod -R g+w /opt/mattermost

# Update the Mattermost configuration
sudo sed -i "s/mmuser/mattermost/" /opt/mattermost/config/config.json
sudo sed -i "s/mostest/$mattermostpassphrase/" /opt/mattermost/config/config.json
sudo sed -i "s/dockerhost/127.0.0.1/" /opt/mattermost/config/config.json
sudo sed -i "s/mattermost_test/mattermost/" /opt/mattermost/config/config.json
sudo sed -i "s/8065/3000/" /opt/mattermost/config/config.json

# Create the Mattermost tables
cd /opt/mattermost/bin/
sudo -u mattermost /opt/mattermost/bin/./platform
cd -

# Correct the MariaDB formatting
mysql -u root -e "ALTER TABLE mattermost.Audits ENGINE = MyISAM;ALTER TABLE mattermost.ChannelMembers ENGINE = MyISAM;ALTER TABLE mattermost.Channels ENGINE = MyISAM;ALTER TABLE mattermost.ClusterDiscovery ENGINE = MyISAM;ALTER TABLE mattermost.Commands ENGINE = MyISAM;ALTER TABLE mattermost.CommandWebhooks ENGINE = MyISAM;ALTER TABLE mattermost.Compliances ENGINE = MyISAM;ALTER TABLE mattermost.Emoji ENGINE = MyISAM;ALTER TABLE mattermost.FileInfo ENGINE = MyISAM;ALTER TABLE mattermost.IncomingWebhooks ENGINE = MyISAM;ALTER TABLE mattermost.Jobs ENGINE = MyISAM;ALTER TABLE mattermost.Licenses ENGINE = MyISAM;ALTER TABLE mattermost.OAuthAccessData ENGINE = MyISAM;ALTER TABLE mattermost.OAuthApps ENGINE = MyISAM;ALTER TABLE mattermost.OAuthAuthData ENGINE = MyISAM;ALTER TABLE mattermost.OutgoingWebhooks ENGINE = MyISAM;ALTER TABLE mattermost.Posts ENGINE = MyISAM;ALTER TABLE mattermost.Preferences ENGINE = MyISAM;ALTER TABLE mattermost.Reactions ENGINE = MyISAM;ALTER TABLE mattermost.Sessions ENGINE = MyISAM;ALTER TABLE mattermost.Status ENGINE = MyISAM;ALTER TABLE mattermost.Systems ENGINE = MyISAM;ALTER TABLE mattermost.TeamMembers ENGINE = MyISAM;ALTER TABLE mattermost.Teams ENGINE = MyISAM;ALTER TABLE mattermost.Tokens ENGINE = MyISAM;ALTER TABLE mattermost.UserAccessTokens ENGINE = MyISAM;ALTER TABLE mattermost.Users ENGINE = MyISAM;"

# Create the Mattermost service
sudo bash -c 'cat > /etc/systemd/system/mattermost.service <<EOF
[Unit]
Description=Mattermost
After=syslog.target network.target mariadb.service

[Service]
Type=notify
WorkingDirectory=/opt/mattermost
User=mattermost
ExecStart=/opt/mattermost/bin/platform
PIDFile=/var/spool/mattermost/pid/master.pid
TimeoutStartSec=3600
LimitNOFILE=49152

[Install]
WantedBy=multi-user.target
EOF'
sudo chmod 664 /etc/systemd/system/mattermost.service

# Prepare the service environment
sudo systemctl daemon-reload

# Configure Mattermost service
sudo systemctl enable mattermost.service

# Configure the firewall
sudo firewall-cmd --add-port=5000/tcp --permanent
sudo firewall-cmd --reload

# Start Mattermost service
sudo systemctl start mattermost.service
clear
cat << "EOF"

                                           %%%%%%
                                       %%%%%%%%.      %%
                                    %%%%%%.          %%%     %%
                                  %%%%%%           %%%%%     %%%%
                                 %%%%%           @%%%%%%      %%%%
                                %%%%%           %%%%%%%%       .%%%
                               %%%%%          %%%%%%%%%%        %%%%
                              %%%%%%         %%%%%%%%%%%         %%%%
                              %%%%%*         %%%%%%%%%%%         %%%%
                              %%%%%%         %%%%%%%%%%%         %%%%
                              %%%%%%           %%%%%%%.          %%%%
                              %%%%%%%                           %%%%%
                              %%%%%%%%                         %%%%%%
                               %%%%%%%%                       %%%%%%
                                %%%%%%%%%%                  %%%%%%%
                                 %%%%%%%%%%%%@          %%%%%%%%%%
                                  @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%/
                                    @%%%%%%%%%%%%%%%%%%%%%%%%%(
                                       %%%%%%%%%%%%%%%%%%%%%
                                           .%%%%%%%%%%%.


EOF
echo "Rocketchat has been successfully deployed. Browse to http://$HOSTNAME:3000 (or http://$IP:3000 if you don't have DNS set up) to begin using the service."
echo "See the "Build, Operate, Maintain" document of the capesstack/capes/mattermost repository on GitHub."
