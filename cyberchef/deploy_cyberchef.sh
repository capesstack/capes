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
########## CyberChef ###########
################################

# Install dependencies
sudo yum install epel-release -y
sudo yum install nginx -y

# Collect CyberChef
sudo curl https://gchq.github.io/CyberChef/cyberchef.htm -o /usr/share/nginx/html/cyberchef.htm

# Make firewall configurations
sudo firewall-cmd --add-port=80/tcp --permanent
sudo firewall-cmd --reload

# Configure the nginx service to start on boot and start it
sudo systemctl enable nginx.service
sudo systemctl start nginx.service

# Install success
clear
cat << "EOF"
MMMMMMMMMMMMMMMMMMMMMmyoooshmMMMNMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMmdhhdh:   `````::```dMMmMMMMMMMMMMMM
MMMMMMMMMMMm+.          ``````````:o:`-hMMMMMMMMMM
MMMMMMMMMMy`            ```````````````+NMMMMMMMMM
MMMMMMMMMm`             ``````````````.hmNMMMMMMMM
MMMMMMMMMh              `````````````````:MMMMMMMM
MMMMMMMMMN.             ```````````````.-+MMMMMMMM
MMMMMMMMMMm-            ``````````````.mMMMMMMMMMM
MMMMMMMMMMMMd+`         ```````````````:NMMMMMMMMM
MMMMMMMMMMMMMM`         ``````````odo-oNMMMMMMMMMM
MMMMMMMMMMMMMM`         ``````````hMMMMMMMMMMMMMMM
MMMMMMMMMMMMMM`         ``````````hMMMMMMMMMMMMMMM
MMMMMMMMMMMMMM:`````````-:::::::::mMMMMMMMMMMMMMMM
MMMMMMMMMMMMMM/.........://///////mMMMMMMMMMMMMMMM
MMMMMMMMMMMMNh:--------`--oooooooodNMMMMMMMMMMMMMM
MMMMMMMMMMMho+///////:` .-+hddddddddNMMMMMMMMMMMMM
MMMMMMMMMMmyyy:--+y+/` `:--+s+yssohdmdhNMMMMMMMMMM
MMMMMMMMMdyyyy-  :hh+ ``o/-/++:---hyyyydMMMMMMMMMM
MMMMMMMMdyyyyy-       ``os--------mmyymMMMMMMMMMMM
MMMMMMMMhyyyyy-      ```oy/-------hhyyydMMMMMMMMMM
MMMMMMMMNyyyyy-       ``:/:-------yhmdhmMMMMMMMMMM
MMMMMMMMMNdhyy-   ``..``oyyys/----yNMMMMMMMMMMMMMM
MMMMMMMMMMMMMN:     ``..//:------:mMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMms:`     .-----/sdMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMmhso+osyhmNMMMMMMMMMMMMMMMMMMMM
EOF
echo "CyberChef successfully installed!"
echo "Browse to http://$HOSTNAME/cyberchef.htm (or http://$IP/cyberchef.htm if you don't have DNS set up) to get started."
echo "See the "Build, Operate, Maintain" document of the capesstack/capes/cyberchef repository on GitHub."
