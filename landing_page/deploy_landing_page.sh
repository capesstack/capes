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
sudo htpasswd -ic /etc/nginx/.htpasswd operator $capespassphrase
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
