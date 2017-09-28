#!/bin/bash

################################
##### Collect Credentials ######
################################

# Create your Mumble passphrase
clear
echo "Create your Mumble SuperUser passphrase and press [Enter]."
read -s mumblepassphrase

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
########### Mumble #############
################################

# Prepare the environment
sudo yum -y install bzip2 && yum -y update
sudo groupadd -r murmur
sudo useradd -r -g murmur -m -d /var/lib/murmur -s /sbin/nologin murmur
sudo mkdir -p /var/log/murmur
sudo chown murmur:murmur /var/log/murmur
sudo chmod 0770 /var/log/murmur

# Download binaries
curl -OL https://github.com/mumble-voip/mumble/releases/download/1.2.19/murmur-static_x86-1.2.19.tar.bz2
tar vxjf murmur-static_x86-1.2.19.tar.bz2
sudo mkdir -p /opt/murmur
sudo cp -r murmur-static_x86-1.2.19/* /opt/murmur
sudo cp murmur-static_x86-1.2.19/murmur.ini /etc/murmur.ini
rm -rf murmur-static_x86-1.2.19.tar.bz2 murmur-static_x86-1.2.19

# Configure /etc/murmur.ini
sudo sed -i 's/database=/database=\/var\/lib\/murmur\/murmur\.sqlite/' /etc/murmur.ini
sudo sed -i 's/\#logfile=murmur\.log/logfile=\/var\/log\/murmur\/murmur\.log/' /etc/murmur.ini
sudo sed -i 's/\#pidfile=/pidfile=\/var\/run\/murmur\/murmur\.pid/' /etc/murmur.ini
sudo sed -i 's/\#registerName=Mumble\ Server/registerName=CAPES\ -\ Mumble\ Server/' /etc/murmur.ini
sudo sed -i 's/port=64738/port=7000/' /etc/murmur.ini

# Configure the firewall
sudo firewall-cmd --add-port=7000/tcp --add-port=7000/udp --permanent
sudo firewall-cmd --reload

# Rotate logs
sudo bash -c 'cat > /etc/logrotate.d/murmur <<EOF
/var/log/murmur/*log {
    su murmur murmur
    dateext
    rotate 4
    missingok
    notifempty
    sharedscripts
    delaycompress
    postrotate
        /bin/systemctl reload murmur.service > /dev/null 2>/dev/null || true
    endscript
}
EOF'

# Creating the systemd service
sudo bash -c 'cat > /etc/systemd/system/murmur.service <<EOF
[Unit]
Description=Mumble Server (Murmur)
Requires=network-online.target
After=network-online.target mariadb.service time-sync.target

[Service]
User=murmur
Type=forking
ExecStart=/opt/murmur/murmur.x86 -ini /etc/murmur.ini
PIDFile=/var/run/murmur/murmur.pid
ExecReload=/bin/kill -s HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF'

# Generate the pid directory for Murmur:
sudo bash -c 'cat > /etc/tmpfiles.d/murmur.conf <<EOF
d /var/run/murmur 775 murmur murmur
EOF'

# Prepare the service environment
sudo systemd-tmpfiles --create /etc/tmpfiles.d/murmur.conf
sudo systemctl daemon-reload

# Set Murmur to start on boot
sudo systemctl enable murmur.service

# Start the Murmur service
sudo systemctl start murmur.service

# Configure the SuperUser account
sudo /opt/murmur/murmur.x86 -ini /etc/murmur.ini -supw $mumblepassphrase

# Success
clear
cat << "EOF"

MMMMMMMMMMMMMMMMMMMMMNmmddmmNMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMNds+:-`````````.-:+ydMMMMMMMMMMMMMMM
MMMMMMMMMMMms:.:/+ydmo      -hmho+::/yNMMMMMMMMMMM
MMMMMMMMNy:..odmmddMMN      +MMNhmmdh:`/hMMMMMMMMM
MMMMMMNs-```dMMh. /MMN      +MMy  /MMM:``-hMMMMMMM
MMMMMd:.`  .MMM`  /MMm      +MMy   sMMy  ``/mMMMMM
MMMMs.``   -MMN   /MMm      +MMy   oMMh   ``.hMMMM
MMMo.``    -MMN   /MNd      /mMy   +MMh     `.yMMM
MMy.``     -MMN   -MNd-    `smMo   +MMh      `.dMM
MN-.`      -Nmm    :dNmhssydmmo    oNNy      ``:MM
Ms.``    :sdMhM`     `-::::-.      ymhNh+.    `.hM
M/.`   .syymMhM`.----------------- ymhNdyy/   `.oM
M:.`  -yoohNMhM`sy//+hMy/mMMy///+M`ymhMmyoso  ``+M
M/.` `hyshNMMhM`s+ +- m+ hMMo :+oM`ymhMNmysy/ `.oM
Ms.``/mmmNMMMhM`s+ o:.m+ yMMo :oyM`ymhMMMNmdh `.hM
MN-.`oMMMMMMMhM`s+ --`h+ sMMo -/oM`ymhMMMMMMm``:MM
MMy.`/MMMMMMMhM`s+ dm ++ yMMo sMMM`ymhMMMMMMh`.dMM
MMMs.`dMMMMMMhM`s+ .``d+ ``-o  `.M`ymhMMMMMN:.yMMM
MMMMy.-mMMMMMhM`+hssyddyssssyssssd`ymhMMMMN+.hMMMM
MMMMMd:.yNMMMhM`                   ymhMMMd:/mMMMMM
MMMMMMMy--+ydym`                   sdhho::hMMMMMMM
MMMMMMMMMy:```        +hdhhho....-/so-`/hMMMMMMMMM
MMMMMMMMMMMms/.``     +dNMNds::///-./yNMMMMMMMMMMM
MMMMMMMMMMMMMMNdy+:-.````````.-/+ydMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMNmmmmmmNMMMMMMMMMMMMMMMMMMMMM

EOF
echo "Murmur (Mumble) has been successfully deployed."
echo "See the "Build, Operate, Maintain" document of the capesstack/capes/mumble repository on GitHub for Mumble configurations of the client and service."
