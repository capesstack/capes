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

# Create your HackMD passphrase
echo "Create your HackMD passphrase for the MySQL database and press [Enter]. You will create your specific HackMD credentials after the installation."
read -s hackmdpassphrase

# Create your Mattermost passphrase
echo "Create your Mattermost passphrase for the MySQL database and press [Enter]. You will create your Mattermost administration credentials after the installation."
read -s mattermostpassphrase

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
sudo yum -y install bzip2 && sudo yum -y update
sudo groupadd -r murmur
sudo useradd -r -g murmur -m -d /var/lib/murmur -s /sbin/nologin murmur
sudo mkdir -p /var/log/murmur
sudo chown murmur:murmur /var/log/murmur
sudo chmod 0770 /var/log/murmur

# Download binaries
curl -OL https://github.com/mumble-voip/mumble/releases/download/1.2.19/murmur-static_x86-1.2.19.tar.bz2
tar xjf murmur-static_x86-1.2.19.tar.bz2
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
sudo sed -i "s/8065/5000/" /opt/mattermost/config/config.json

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

################################
############ HackMD ############
################################

# Install dependencies
sudo yum install npm gcc-c++ git -y

# Stage HackMD for building
sudo npm install -g uws node-gyp tap webpack grunt yarn
sudo yarn add -D webpack-cli
sudo git clone https://github.com/hackmdio/hackmd.git /opt/hackmd/
cd /opt/hackmd
sudo bin/setup
cd -

# Set up the HackMD database
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

################################
########## Gitea ###############
################################

# Big thanks to @seven62 for fixing the Git 2.x and MariaDB issues and getting the service back in the green!

# Install dependencies
sudo yum install http://opensource.wandisco.com/centos/7/git/x86_64/wandisco-git-release-7-2.noarch.rpm -y
sudo yum update git -y

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

# Create the Gitea user
sudo useradd -s /usr/sbin/nologin gitea

# Grab Gitea and make it a home
sudo mkdir -p /opt/gitea
sudo curl -L https://dl.gitea.io/gitea/master/gitea-master-linux-amd64 -o /opt/gitea/gitea
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
########### TheHive ############
################################

# Install Dependencies
sudo yum install java-1.8.0-openjdk.x86_64 gcc-c++ -y
sudo yum groupinstall "Development Tools" -y
sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
sudo yum install https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.6.0.rpm https://centos7.iuscommunity.org/ius-release.rpm libffi-devel python-devel python-pip ssdeep-devel ssdeep-libs perl-Image-ExifTool file-devel -y
sudo yum install python36u python36u-pip python36u-devel -y

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
sudo git clone https://github.com/TheHive-Project/Cortex-Analyzers.git /opt/cortex/

# Install TheHive Project and Cortex
# TheHive Project is the incident tracker, Cortex is your analysis engine.
# If you're going to be using this offline, you can remove the Cortex install (sudo yum install thehive -y).
sudo rpm --import https://dl.bintray.com/cert-bdf/rpm/repodata/repomd.xml.key
sudo yum install https://dl.bintray.com/thehive-project/rpm-stable/thehive-project-release-1.1.0-1.noarch.rpm -y
#sudo yum install https://dl.bintray.com/cert-bdf/rpm/thehive-project-release-1.0.0-3.noarch.rpm -y
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

# Add the future Python package, install the Cortex Analyzers, and adjust the Python 3 path to 3.6
sudo pip install future
for d in /opt/cortex/analyzers/*/ ; do (cat $d/requirements.txt >> requirements.staged); done
sort requirements.staged | uniq > requirements.txt
rm requirements.staged
sed -i '/cortexutilsdatetime/d' requirements.txt
sed -i '/urllib2/d' requirements.txt
sed -i '/oletools>=0.52/d' requirements.txt
sed -i "s/urllib2/urllib2\;python_version<='2.7'/" requirements.txt
sed -i "s/ssdeep/ssdeep\;python_version>='3.5'/" requirements.txt
echo "urllib3;python_version>='3.5'" >> requirements.txt
sed -i '/requestscortexutils/d' requirements.txt
sudo /usr/bin/pip2.7 install -r requirements.txt
sudo /usr/bin/pip3.6 install -r requirements.txt
rm requirements.txt
for d in /opt/cortex/analyzers/* ; do (sudo /usr/bin/sed -i 's/python3/python3.6/' $d/*.py); done

# for removal
#sed -i '/cortexutilsdatetime/d' requirements.txt
#sed -i '/requestscortexutils/d' requirements.txt
#sudo /usr/bin/pip2.7 install -r requirements.txt
#sudo /usr/bin/pip3.6 install -r requirements.txt
#rm requirements.txt
#for d in /opt/cortex/analyzers/* ; do (sudo /usr/bin/sed -i 's/python3/python3.6/' $d/*.py); done
# end for removal

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

# Connect TheHive to Cortex
sudo bash -c 'cat >> /etc/thehive/application.conf <<EOF
# Cortex
play.modules.enabled += connectors.cortex.CortexConnector
cortex {
  "CORTEX-SERVER-ID" {
  url = "http://`hostname -I | sed -e 's/[[:space:]]*$//'`:9001"
  key = "Cortex-API-key-see-post-installation-instructions"
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
######## Heartbeat #############
################################

sudo yum install -y https://artifacts.elastic.co/downloads/beats/heartbeat/heartbeat-5.6.5-x86_64.rpm
sudo cp beats/heartbeat.yml /etc/heartbeat/heartbeat.yml
sudo sed -i "s/passphrase/$capespassphrase/" /etc/heartbeat/heartbeat.yml

################################
######### Filebeat #############
################################
sudo yum install -y https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-5.6.5-x86_64.rpm
sudo cp beats/filebeat.yml /etc/filebeat/filebeat.yml
sudo /usr/share/elasticsearch/bin/elasticsearch-plugin install ingest-user-agent
sudo /usr/share/elasticsearch/bin/elasticsearch-plugin install ingest-geoip

################################
######## Metricbeat ############
################################

sudo yum install -y https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-5.6.5-x86_64.rpm
sudo cp beats/metricbeat.yml /etc/metricbeat/metricbeat.yml
sudo sed -i "s/hostname/$HOSTNAME/" /etc/metricbeat/metricbeat.yml

################################
########### Kibana #############
################################

sudo yum install -y https://artifacts.elastic.co/downloads/kibana/kibana-5.6.5-x86_64.rpm
sudo sed -i "s/#server\.host: \"localhost\"/server\.host: \"0\.0\.0\.0\"/" /etc/kibana/kibana.yml

################################
########## Firewall ############
################################

# Port 80 - Nginx
# Port 3000 - HackMD
# Port 4000 - Gitea
# Port 5000 - Mattermost
# Port 5601 - Kibana
# Port 7000 - Mumble
# Port 9000 - TheHive
# Port 9001 - Cortex (TheHive Analyzer Plugin)
sudo firewall-cmd --add-port=80/tcp --add-port=3000/tcp --add-port=4000/tcp --add-port=5000/tcp --add-port=5601/tcp --add-port=9000/tcp --add-port=9001/tcp --add-port=7000/tcp --add-port=7000/udp --permanent
sudo firewall-cmd --reload

################################
########## Services ############
################################

# Prepare the service environment
sudo systemd-tmpfiles --create /etc/tmpfiles.d/murmur.conf
sudo systemctl daemon-reload

# Configure services for autostart
sudo systemctl enable nginx.service
sudo systemctl enable kibana.service
sudo systemctl enable heartbeat.service
sudo systemctl enable filebeat.service
sudo systemctl enable metricbeat.service
sudo systemctl enable mariadb.service
sudo systemctl enable hackmd.service
sudo systemctl enable gitea.service
sudo systemctl enable mattermost.service
sudo systemctl enable elasticsearch.service
sudo systemctl enable thehive.service
sudo systemctl enable cortex.service
sudo systemctl enable murmur.service

# Start all the services
sudo systemctl start elasticsearch.service
sudo systemctl start kibana.service
sudo systemctl start cortex.service
sudo systemctl start gitea.service
sudo systemctl start hackmd.service
sudo systemctl start thehive.service
sudo systemctl start murmur.service
sudo systemctl start nginx.service
sudo systemctl start heartbeat.service
sudo systemctl start metricbeat.service
sudo systemctl start filebeat.service
sudo systemctl start mattermost.service

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

################################
## Copy CAPES Function Check ###
################################
sudo cp capes_processes /usr/local/bin
sudo chmod 0755 /usr/local/bin/capes_processes

################################
########## Remove gcc ##########
################################
sudo yum -y remove gcc-c++

###################################
###### Install some default #######
## visualizations and dashboards ##
###################################
/usr/share/metricbeat/scripts/./import_dashboards
/usr/share/heartbeat/scripts/./import_dashboards

###############################
### Clear your Bash history ###
###############################
# We don't want anyone snooping around and seeing any passphrases you set
cat /dev/null > ~/.bash_history && history -c

################################
######### Success Page #########
################################
clear
echo "The Mattermost passphrase for the MariaDB database is: "$mattermostpassphrase
echo "The Gitea passphrase for the MariaDB database is: "$giteapassphrase
echo "The HackMD passphrase for the MariaDB database and the service administration account is: "$hackmdpassphrase
echo "The Mumble SuperUser passphrase is: "$mumblepassphrase
echo "The CAPES landing passphrase for the account \"operator\" is: "$capespassphrase
echo "Please see the "Build, Operate, Maintain" documentation for the post-installation steps."
echo "The CAPES landing page has been successfully deployed. Browse to http://$HOSTNAME (or http://$IP if you don't have DNS set up) to begin using the services."
