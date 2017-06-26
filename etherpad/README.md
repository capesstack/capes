# Etherpad

sudo yum install gzip git curl python openssl-devel epel-release -y && sudo yum groupinstall "Development Tools" -y
sudo yum install nodejs mariadb-server -y
sudo systemctl start mariadb.service
sudo systemctl enable mariadb.service
sudo mysql_secure_installation
### Need a way to auto-complete this
mysql -u root -p

CREATE DATABASE etherpad;
GRANT ALL PRIVILEGES ON etherpad.* TO 'etherpad'@'localhost' IDENTIFIED BY 'password';
FLUSH PRIVILEGES;
\q

sudo adduser etherpad 
sudo mkdir -p /opt/etherpad 
sudo install -d -m 755 -o etherpad -g etherpad /opt/etherpad 

sudo firewall-cmd --add-port=9001/tcp --permanent
sudo firewall-cmd --reload

sudo git clone https://github.com/ether/etherpad-lite.git /opt/etherpad
sudo cp /opt/etherpad/settings.json.template /opt/etherpad/settings.json
sudo vi /opt/etherpad/settings.json
### Need to do this automated, maybe by including a settings.json document with CAPES?
Remove lines 39 - 56 with this:
  "dbType" : "mysql",
  "dbSettings" : {
                   "user"    : "etherpad",
                   "host"    : "localhost",
                   "password": "password_set_above",
                   "database": "etherpad",
                   "charset" : "utf8mb4"
                 },
Change "trustProxy" : false to "trustProxy" : true <- test, probably needed with nginx, but maybe not?
Remove lines 157 - 166 <- check spacing, tabs, and ensure I didn't miss a comment marker
      "users": {
        "admin": {
        "password": "changeme",
        "is_admin": true
      },
    },

### this will be needed, but may conflict with `sudo install -d -m...` above, check this
sudo chown -R etherpad:etherpad /opt/etherpad

sudo cat << __EOF | sudo tee /usr/lib/systemd/system/etherpad.service
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
__EOF

sudo systemctl enable etherpad
sudo systemctl start etherpad



/opt/etherpad/bin/./run.sh
http://IP:9001/admin
Install the adminpage plugin, restart Etherpad

https://www.rosehosting.com/blog/install-etherpad-on-a-centos-7-vps/
https://github.com/ether/etherpad-lite#gnulinux-and-other-unix-like-systems
