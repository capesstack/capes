#!/bin/bash

# Set your IP address as a variable. This is for instructions below.
IP="$(hostname -I | sed -e 's/[[:space:]]*$//')"

sudo systemctl enable chronyd.service
sudo systemctl start chronyd.service

sudo yum install epel-release firewalld -y && sudo yum update -y
sudo yum install nginx -y
sudo sed -i 's/your-hostname/$HOSTNAME/' index.html
sudo cp -r . /usr/share/nginx/html/
sudo firewall-cmd --add-port=80/tcp --permanent
sudo firewall-cmd --reload
sudo systemctl enable nginx
sudo systemctl start nginx

clear
echo "The CAPES landing page has been successfully deployed. Browse to http://$HOSTNAME (or http://$IP if you don't have DNS set up) to begin using the services."
