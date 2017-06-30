#!/bin/bash

# Note, change your MariaSQL password on line 10.

sudo yum install -y mariadb-server git unzip
sudo systemctl start mariadb
sudo systemctl enable mariadb

mysql -u root -e "CREATE DATABASE gogs;"
mysql -u root -e "GRANT ALL PRIVILEGES ON gogs.* TO 'gogs'@'localhost' IDENTIFIED BY 'changeme';"
mysql -u root -e "FLUSH PRIVILEGES;"

mysql_secure_installation

sudo useradd gogs

sudo firewall-cmd --add-port=3000/tcp --permanent
sudo firewall-cmd --reload

sudo mkdir /opt/gogs
curl -L https://dl.gogs.io/0.11.19/linux_amd64.zip -o gogs.zip
sudo unzip gogs.zip -d /opt/
rm gogs.zip

sudo chown -R gogs:gogs /opt/gogs

# may be needed to run for the first time
# sudo runuser -l gogs -c "/opt/gogs/gogs web"

sudo bash -c 'cat > /usr/lib/systemd/system/gogs.service <<EOF
[Unit]
Description=GoGS
After=syslog.target network.target mariadb.service
[Service]
Type=simple
User=gogs
Group=gogs
WorkingDirectory=/opt/gogs/
ExecStart=/opt/gogs/gogs web
Restart=always
Environment=USER=gogs HOME=/home/gogs
[Install]
WantedBy=multi-user.target
EOF'

sudo systemctl enable gogs.service
sudo systemctl start gogs.service

echo "GoGS Successfully Installed!"
echo "Your First boot will take a couple minutes while the final npm dependencies are grabbed."
echo "Browse to http://etherpad_server:3000 to get started."

# update to this to avoid hard links to versions (line 20)
# https://gogs.io/docs/installation/install_from_source.html
