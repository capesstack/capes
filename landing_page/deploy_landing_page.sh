#!/bin/bash

# Create your CAPES Landing Page passphrase
echo "Create your CAPES Landing Page passphrase for the account \"operator\" and press [Enter]."
read -s capespassphrase

# Set your IP address as a variable. This is for instructions below.
IP="$(hostname -I | sed -e 's/[[:space:]]*$//')"

sudo systemctl enable chronyd.service
sudo systemctl start chronyd.service

sudo yum install epel-release -y && sudo yum update -y
sudo yum install nginx httpd-tools -y
sudo sed -i 's/your-ip/$IP/' index.html
sudo cp -r . /usr/share/nginx/html/
sudo firewall-cmd --add-port=80/tcp --permanent
sudo firewall-cmd --reload

# Create basic authentiation for Nginx
sudo htpasswd -bc /etc/nginx/.htpasswd operator $capespassphrase
sudo sed -i '43 a \\tauth_basic "CAPES Login";' /etc/nginx/nginx.conf
sudo sed -i '44 a \\tauth_basic_user_file /etc/nginx/.htpasswd;' /etc/nginx/nginx.conf

# Start Nginx and set it for autoboot
sudo systemctl enable nginx
sudo systemctl start nginx

###############################
### Clear your Bash history ###
###############################
cat /dev/null > ~/.bash_history && history -c

clear
echo "The CAPES landing passphrase for the account \"operator\" is: "$capespassphrase
echo "The CAPES landing page has been successfully deployed. Browse to http://$HOSTNAME (or http://$IP if you don't have DNS set up) to begin using the services."
