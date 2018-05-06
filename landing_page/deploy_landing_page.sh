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

# Prepare the service environment
sudo systemctl daemon-reload

# Start Nginx and set it for autoboot
sudo systemctl enable nginx
sudo systemctl start nginx

###############################
### Clear your Bash history ###
###############################
# We don't want anyone snooping around and seeing any passphrases you set
cat /dev/null > ~/.bash_history && history -c

clear
echo "The CAPES landing passphrase for the account \"operator\" is: "$capespassphrase
echo "The CAPES landing page has been successfully deployed. Browse to http://$HOSTNAME (or http://$IP if you don't have DNS set up) to begin using the services."
