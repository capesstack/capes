#!/bin/bash

################################
######## repo_gpgcheck #########
################################

# repo_gpgcheck either 1 or 0 tells yum whether or not it should perform a GPG signature check on the repodata. When this is set in the [main] section of /etc/yum.conf, it sets the default for all repositories. The default is 0.
# Currently Red Hat products (Customer Portal, Red Hat Satellite, RHUI..etc) does not support repo gpgcheck option yet
# Yum tries to download repomd.xml.asc as repo_gpgcheck was set to 1, however yum was unable to locate repomd.xml.asc on the epel server due to GPG armor not being enabled on the server side
# This appears to be caused by an applied Security Profile in the build with CentOS 7.4 - additional testing is being performed
# Until then, we are going to set repo_gpgcheck back to the default of 0
# https://rhel7stig.readthedocs.io/en/latest/high.html?highlight=repo_gpgcheck
# https://access.redhat.com/solutions/2850911
sudo sed -i 's/repo_gpgcheck=1/repo_gpgcheck=0/' /etc/yum.conf

# Create Etherpad password
echo "Create your Etherpad password for the MySQL database and the service administration account then press [Enter]"
read -s etherpadpassword

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
########### Etherpad ###########
################################

# Install dependencies
sudo yum install git openssl-devel epel-release expect -y && sudo yum groupinstall "Development Tools" -y
sudo yum install nodejs mariadb-server -y

# Configure MySQL
sudo systemctl start mariadb.service
mysql -u root -e "CREATE DATABASE etherpad;"
mysql -u root -e "GRANT ALL PRIVILEGES ON etherpad.* TO 'etherpad'@'localhost' IDENTIFIED BY '$etherpadpassword';"
mysql -u root -e "FLUSH PRIVILEGES;"

# Add the Etherpad user
sudo useradd -s /usr/sbin/nologin etherpad

# Get the Etherpad packages
sudo mkdir -p /opt/etherpad
sudo git clone https://github.com/ether/etherpad-lite.git /opt/etherpad

# Configure the Etherpad settings
sudo bash -c 'cat > /opt/etherpad/settings.json <<EOF
{
  "title": "CAPES Etherpad",
  "favicon": "favicon.ico",
  "ip": "0.0.0.0",
  "port" : 5000,
  "showSettingsInAdminPage" : true,
   "dbType" : "mysql",
   "dbSettings" : {
                    "user"    : "etherpad",
                    "host"    : "localhost",
                    "password": "etherpadpassword",
                    "database": "etherpad",
                    "charset" : "utf8mb4"
                  },
  "defaultPadText" : "Welcome to the CAPES Etherpad.\n\nThis pad text is synchronized as you type, so that everyone viewing this page sees the same text. This allows you to collaborate seamlessly on documents.",
  "padOptions": {
    "noColors": false,
    "showControls": true,
    "showChat": true,
    "showLineNumbers": true,
    "useMonospaceFont": false,
    "userName": false,
    "userColor": false,
    "rtl": false,
    "alwaysShowChat": false,
    "chatAndUsers": false,
    "lang": "en-gb"
  },
  "padShortcutEnabled" : {
    "altF9"     : true, /* focus on the File Menu and/or editbar */
    "altC"      : true, /* focus on the Chat window */
    "cmdShift2" : true, /* shows a gritter popup showing a line author */
    "delete"    : true,
    "return"    : true,
    "esc"       : true, /* in mozilla versions 14-19 avoid reconnecting pad */
    "cmdS"      : true, /* save a revision */
    "tab"       : true, /* indent */
    "cmdZ"      : true, /* undo/redo */
    "cmdY"      : true, /* redo */
    "cmdI"      : true, /* italic */
    "cmdB"      : true, /* bold */
    "cmdU"      : true, /* underline */
    "cmd5"      : true, /* strike through */
    "cmdShiftL" : true, /* unordered list */
    "cmdShiftN" : true, /* ordered list */
    "cmdShift1" : true, /* ordered list */
    "cmdShiftC" : true, /* clear authorship */
    "cmdH"      : true, /* backspace */
    "ctrlHome"  : true, /* scroll to top of pad */
    "pageUp"    : true,
    "pageDown"  : true
  },
  "suppressErrorsInPadText" : false,
  "requireSession" : false,
  "editOnly" : false,
  "sessionNoPassword" : false,
  "minify" : true,
  "maxAge" : 21600, // 60 * 60 * 6 = 6 hours
  "abiword" : null,
  "soffice" : null,
  "tidyHtml" : null,
  "allowUnknownFileEnds" : true,
  "requireAuthentication" : false,
  "requireAuthorization" : false,
  "trustProxy" : true,
  "disableIPlogging" : false,
  "automaticReconnectionTimeout" : 0,
  "users": {
    "admin": {
      "password": "etherpadpassword",
      "is_admin": true
    },
  },
  "socketTransportProtocols" : ["xhr-polling", "jsonp-polling", "htmlfile"],
  "loadTest": false,
  "indentationOnNewLine": true,
  "toolbar": {
    "left": [
      ["bold", "italic", "underline", "strikethrough"],
      ["orderedlist", "unorderedlist", "indent", "outdent"],
      ["undo", "redo"],
      ["clearauthorship"]
    ],
    "right": [
      ["importexport", "timeslider", "savedrevision"],
      ["settings", "embed"],
      ["showusers"]
    ],
    "timeslider": [
      ["timeslider_export", "timeslider_returnToPad"]
    ]
  },
  "loglevel": "INFO",
  "logconfig" :
    { "appenders": [
        { "type": "console"
        //, "category": "access"// only logs pad access
        }
      ]
    }
}
EOF'
sudo sed -i "s/etherpadpassword/$etherpadpassword/" /opt/etherpad/settings.json

# Give the Etherpad user ownership of the /opt/etherpad directory
sudo chown -R etherpad:etherpad /opt/etherpad

# Create the systemd Etherpad service
sudo bash -c 'cat > /usr/lib/systemd/system/etherpad.service <<EOF
[Unit]
Description=The Etherpad server
After=network.target remote-fs.target nss-lookup.target
[Service]
ExecStart=/opt/etherpad/bin/run.sh
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=etherpad
User=etherpad
[Install]
WantedBy=multi-user.target
EOF'

# Make firewall configurations
sudo firewall-cmd --add-port=5000/tcp --permanent
sudo firewall-cmd --reload

# Configure the Etherpad service to start on boot and start it
# Your first boot will take a few minutes while the final npm dependencies are grabbed
sudo systemctl enable etherpad.service
sudo systemctl start etherpad.service

# Secure MySQL
mysql_secure_installation

# Install success
clear
cat << "EOF"
            :sssso.
           sy`:+--d-
           h+`hms`h+
           .o sM:.o
             .mMh`
             sMMM:
            `NNMNh
            sMdNdM/
           .moNMmsd
           oNs+N/hM/
          .doyhMysod`
          oy+yyNsy/m:
         `Nm: -N `oMd`
         os:syyNsyo-d/
        .m``/yhMhs: :d
        ohyy/`-N .+ysm/
       .dds:` -N  ./hdd`
       oo ./sysNoso:` d:
      `d.`-/ymMMMds/. /h`
      omhNMms/:N./ymMmyN/
     `Nms/.   -N    ./yNd
      -+ys+-` -N  `:oss/`
          -+sssNoss/.
             `./`
EOF
echo "Etherpad successfully installed!"
echo "Your First boot will take a couple minutes while the final npm dependencies are grabbed."
echo "Browse to http://$HOSTNAME:5000 (or http://$IP:5000 if you don't have DNS set up) to get started, /admin for administrative functions."
echo "See the "Build, Operate, Maintain" document of the capesstack/capes/etherpad repository on GitHub."
