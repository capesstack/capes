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
# Create your Gitea passphrase
echo "Create your Gitea passphrase for the MySQL database and press [Enter]. You will create your Gitea administration credentials after the installation."
read -s giteapassphrase

# Create Etherpad passphrase
echo "Create your Etherpad passphrase for the MySQL database and the service administration account then press [Enter]"
read -s etherpadpassphrase

# Create your Mumble passphrase
echo "Create your Mumble SuperUser passphrase and press [Enter]."
read -s mumblepassphrase

# Create your CAPES Landing Page passphrase
echo "Create your CAPES Landing Page passphrase for the account \"operator\" and press [Enter]."
read -s capespassphrase

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
sudo yum install nodejs GraphicsMagick npm mongodb-org gcc-c++ -y

# Configure npm
sudo npm install -g inherits n
sudo n 4.5

# Build RocketChat
sudo mkdir /opt/rocketchat
curl -L https://download.rocket.chat/stable -o rocketchat.tar.gz
echo "This next part takes a few minutes, everything is okay...go have a scone."
sudo tar zxf rocketchat.tar.gz -C /opt/rocketchat/
sudo mv /opt/rocketchat/bundle /opt/rocketchat/Rocket.Chat
rm rocketchat.tar.gz
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
########## Gitea ###############
################################

# Install dependencies
sudo yum install mariadb-server -y
sudo systemctl start mariadb.service

# Configure MariaDB
mysql -u root -e "CREATE DATABASE gitea;"
mysql -u root -e "GRANT ALL PRIVILEGES ON gitea.* TO 'gitea'@'localhost' IDENTIFIED BY '$giteapassphrase';"
mysql -u root -e "FLUSH PRIVILEGES;"

# Create the Gitea user
sudo useradd -s /usr/sbin/nologin gitea

# Grab Gitea and make it a home
sudo mkdir -p /opt/gitea
sudo curl -o /opt/gitea/gitea https://dl.gitea.io/gitea/master/gitea-master-linux-amd64
sudo chown -R gitea:gitea /opt/gitea
sudo chmod 744 /opt/gitea/gitea

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

################################
########### Etherpad ###########
################################

# Install dependencies
sudo yum install openssl-devel -y && sudo yum groupinstall "Development Tools" -y

# Configure MySQL
mysql -u root -e "CREATE DATABASE etherpad;"
mysql -u root -e "GRANT ALL PRIVILEGES ON etherpad.* TO 'etherpad'@'localhost' IDENTIFIED BY '$etherpadpassphrase';"
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
                    "password": "etherpadpassphrase",
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
      "password": "etherpadpassphrase",
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
sudo sed -i "s/etherpadpassphrase/$etherpadpassphrase/" /opt/etherpad/settings.json

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

################################
########### TheHive ############
################################

# Install Dependencies
sudo yum install java-1.8.0-openjdk.x86_64  -y
sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
sudo yum install https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.6.0.rpm libffi-devel python-devel python-pip ssdeep-devel ssdeep-libs perl-Image-ExifTool file-devel -y

# Configure Elasticsearch
sudo bash -c 'cat > /etc/elasticsearch/elasticsearch.yml <<EOF
network.host: 127.0.0.1
cluster.name: hive
script.inline: true
thread_pool.index.queue_size: 100000
thread_pool.search.queue_size: 100000
thread_pool.bulk.queue_size: 1000
EOF'

# Collect the Cortex analyzers
sudo git clone https://github.com/CERT-BDF/Cortex-Analyzers.git /opt/cortex/

# Collect the Cortex Report Templates
sudo curl -L https://dl.bintray.com/cert-bdf/thehive/report-templates.zip -o /opt/cortex/report-templates.zip

# Install TheHive Project and Cortex
# TheHive Project is the incident tracker, Cortex is your analysis engine.
# If you're going to be using this offline, you can remove the Cortex install (sudo yum install thehive -y).
sudo rpm --import https://dl.bintray.com/cert-bdf/rpm/repodata/repomd.xml.key
sudo yum install https://dl.bintray.com/cert-bdf/rpm/thehive-project-release-1.0.0-3.noarch.rpm -y
sudo yum install thehive cortex -y

# Configure TheHive Project secret key
(cat << _EOF_
# Secret key
# ~~~~~
# The secret key is used to secure cryptographics functions.
# If you deploy your application to several instances be sure to use the same key!
play.crypto.secret="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)"
_EOF_
) | sudo tee -a /etc/thehive/application.conf

# Configure Cortex secret key
(cat << _EOF_
# Secret key
# ~~~~~
# The secret key is used to secure cryptographics functions.
# If you deploy your application to several instances be sure to use the same key!
play.crypto.secret="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)"
_EOF_
) | sudo tee -a /etc/cortex/application.conf

# Update Pip...just because it's ludicious that installing it doesn't bring the updated version
sudo pip install --upgrade pip

# Add the future Python package and then install the Cortex Python dependencies
sudo pip install future
for d in /opt/cortex/analyzers/*/ ; do (cat $d/requirements.txt >> requirements.staged); done
sort requirements.staged | uniq > requirements.txt
rm requirements.staged
sudo pip install -r requirements.txt
rm requirements.txt

# Update the location of the analyzers
sudo sed -i 's/path\/to\/Cortex\-Analyzers/\/opt\/cortex/' /etc/cortex/application.conf

# Ensure that thehive and cortex users owns it's directories
sudo chown -R thehive:thehive /opt/thehive
sudo chown thehive:thehive /etc/thehive/application.conf
sudo chmod 640 /etc/thehive/application.conf
sudo chown -R cortex:cortex /opt/cortex
sudo chown cortex:cortex /etc/cortex/application.conf
sudo chmod 640 /etc/cortex/application.conf

# Configure Cortex to run on port 9001 instead of the default 9000, which is shared with TheHive
sudo sed -i '16i\\t-Dhttp.port=9001 \\' /etc/systemd/system/cortex.service
sudo systemctl daemon-reload

# Connect TheHive to Cortex
sudo bash -c 'cat >> /etc/thehive/application.conf <<EOF
# Cortex
play.modules.enabled += connectors.cortex.CortexConnector
cortex {
  "CORTEX-SERVER-ID" {
  url = "http://$HOSTNAME:9001"
  }
}
EOF'

################################
############ Nginx #############
################################

# Install dependencies
sudo yum install nginx httpd-tools -y

# Create basic authentiation for Nginx
sudo htpasswd -bc /etc/nginx/.htpasswd operator $capespassphrase
sudo sed -i '43 a \\tauth_basic "CAPES Login";' /etc/nginx/nginx.conf
sudo sed -i '44 a \\tauth_basic_user_file /etc/nginx/.htpasswd;' /etc/nginx/nginx.conf

# Update the landing page index file
sed -i "s/your-ip/$IP/" landing_page/index.html

# Move landing page framework into Nginx's working directory
sudo cp -r landing_page/* /usr/share/nginx/html/

# Perform a little housekeeping
sudo rm /usr/share/nginx/html/build_operate_maintain.md /usr/share/nginx/html/deploy_landing_page.sh /usr/share/nginx/html/README.md

################################
########## CyberChef ###########
################################

# Collect CyberChef
sudo curl https://gchq.github.io/CyberChef/cyberchef.htm -o /usr/share/nginx/html/cyberchef.htm

################################
########## Firewall ############
################################
# Port 80 - Nginx
# Port 3000 - RocketChat
# Port 4000 - Gitea
# Port 5000 - Etherpad
# Port 7000 - Mumble
# Port 9000 - TheHive
# Port 9001 - Cortex (TheHive Analyzer Plugins)
# Port 9002 - HippoCampe (TheHive Threat Feed Plugin)
sudo firewall-cmd --add-port=80/tcp --add-port=3000/tcp --add-port=4000/tcp --add-port=5000/tcp --add-port=9000/tcp --add-port=9001/tcp --add-port=7000/tcp --add-port=7000/udp --permanent
sudo firewall-cmd --reload

################################
########## Services ############
################################

# Prepare the service environment
sudo systemd-tmpfiles --create /etc/tmpfiles.d/murmur.conf
sudo systemctl daemon-reload

# Configure services for autostart
sudo systemctl enable nginx.service
sudo systemctl enable mariadb.service
sudo systemctl enable gitea.service
sudo systemctl enable mongod.service
sudo systemctl enable rocketchat.service
sudo systemctl enable etherpad.service
sudo systemctl enable elasticsearch.service
sudo systemctl enable thehive.service
sudo systemctl enable cortex.service
sudo systemctl enable murmur.service

# Start all the services
sudo systemctl start elasticsearch.service
sudo systemctl start cortex.service
sudo systemctl start gitea.service
sudo systemctl start thehive.service
sudo systemctl start mongod.service
sudo systemctl start etherpad.service
sudo systemctl start rocketchat.service
sudo systemctl start murmur.service
sudo systemctl start nginx.service

# Configure the Murmur SuperUser account
sudo /opt/murmur/murmur.x86 -ini /etc/murmur.ini -supw $mumblepassphrase

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

################################
######### Success Page #########
################################
clear
echo "The Gitea passphrase for the MySQL database is: "$giteapassphrase
echo "The Etherpad passphrase for the MySQL database and the service administration account is: "$etherpadpassphrase
echo "The Mumble SuperUser passphrase is: "$mumblepassphrase
echo "The CAPES landing passphrase for the account \"operator\" is: "$capespassphrase
echo "The CAPES landing page has been successfully deployed. Browse to http://$HOSTNAME (or http://$IP if you don't have DNS set up) to begin using the services."
