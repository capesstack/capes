#!/bin/bash

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

# Make sure you set your hostname CORRECTLY vs. like an animal (manually in /etc/hostname)
# Feel free to change the hostname in accordance with your local policy.
sudo hostnamectl set-hostname misp

# We need some packages from the Extra Packages for Enterprise Linux repository
sudo yum install epel-release firewalld -y && sudo yum update -y
sudo yum install centos-release-scl -y

# Install the dependencies:
sudo yum install gcc git httpd zip redis mariadb mariadb-server python-devel python-pip libxslt-devel zlib-devel rh-php56 rh-php56-php-fpm rh-php56-php-devel rh-php56-php-mysqlnd rh-php56-php-mbstring rh-php56-php-xml rh-php56-php-bcmath php-redis python-lxml python-dateutil php-mbstring python-six -y

# Start rh-php56-php-fpm
sudo systemctl enable rh-php56-php-fpm.service
sudo systemctl start rh-php56-php-fpm.service

# Start a new shell with rh-php56 enabled
source /opt/rh/rh-php56/enable
# scl enable rh-php56 bash <- may not be needed
pear channel-update pear.php.net
sudo pear install Crypt_GPG

# GPG needs lots of entropy, haveged provides entropy
sudo yum install haveged -y
sudo systemctl enable haveged.service
sudo systemctl start haveged.service

# Enable and start redis
sudo systemctl enable redis.service
sudo systemctl start redis.service

# Download MISP using git in the /var/www/ directory.
cd /var/www/
sudo git clone https://github.com/MISP/MISP.git
cd /var/www/MISP
# git checkout tags/$(git describe --tags `git rev-list --tags --max-count=1`) <- didn't use this as a test
# if the last shortcut doesn't work, specify the latest version manually
# example: git checkout tags/v2.4.XY
# the message regarding a "detached HEAD state" is expected behaviour
# (you only have to create a new branch, if you want to change stuff and do a pull request for example)

# Make git ignore filesystem permission differences
sudo git config core.filemode false

# Install Mitre's STIX and its dependencies
sudo pip install --upgrade pip
sudo pip install importlib
cd /var/www/MISP/app/files/scripts
sudo git clone https://github.com/CybOXProject/python-cybox.git
sudo git clone https://github.com/STIXProject/python-stix.git
cd /var/www/MISP/app/files/scripts/python-cybox
# git checkout v2.1.0.12 <- maybe not necessary
sudo git config core.filemode false
sudo python setup.py install
cd /var/www/MISP/app/files/scripts/python-stix
# git checkout v1.1.1.4 <- maybe not necessary
sudo git config core.filemode false
sudo python setup.py install

# install mixbox to accomodate the new STIX dependencies:
cd /var/www/MISP/app/files/scripts/
sudo git clone https://github.com/CybOXProject/mixbox.git
cd /var/www/MISP/app/files/scripts/mixbox
# git checkout v1.0.2 <- maybe not necessary
sudo git config core.filemode false
sudo python setup.py install

# CakePHP
cd /var/www/MISP
sudo git submodule init
sudo git submodule update

# Once done, install CakeResque along with its dependencies if you intend to use the built in background jobs:
cd /var/www/MISP/app
# look into this: https://getcomposer.org/doc/faqs/how-to-install-untrusted-packages-safely.md
sudo php composer.phar require kamisama/cake-resque:4.1.2
sudo php composer.phar config vendor-dir Vendor
sudo php composer.phar install
# pecl install redis-2.2.8 <- likely can be commented out
sudo echo "extension=redis.so" > /etc/opt/rh/rh-php56/php-fpm.d/redis.ini
sudo ln -s ../php-fpm.d/redis.ini /etc/opt/rh/rh-php56/php.d/99-redis.ini
sudo systemctl restart rh-php56-php-fpm.service

# If you have not yet set a timezone in php.ini
# You can get a list of available timezones through "timedatectl list-timezones"
sudo sh -c 'echo "date.timezone = "UTC"" > /etc/opt/rh/rh-php56/php-fpm.d/timezone.ini'
sudo ln -s ../php-fpm.d/timezone.ini /etc/opt/rh/rh-php56/php.d/99-timezone.ini

# To use the scheduler worker for scheduled tasks, do the following:
sudo cp -fa /var/www/MISP/INSTALL/setup/config.php /var/www/MISP/app/Plugin/CakeResque/Config/config.php

# Make sure the permissions are set correctly
# sudo chown -R root:apache /var/www/MISP
# sudo find /var/www/MISP -type d -exec chmod g=rx {} \;
# sudo chmod -R g+r,o= /var/www/MISP
# sudo chown apache:apache /var/www/MISP/app/files
# sudo chown apache:apache /var/www/MISP/app/files/terms
# sudo chown apache:apache /var/www/MISP/app/files/scripts/tmp
# sudo chown apache:apache /var/www/MISP/app/Plugin/CakeResque/tmp
# sudo chown -R apache:apache /var/www/MISP/app/tmp
# sudo chown -R apache:apache /var/www/MISP/app/webroot/img/orgs
# sudo chown -R apache:apache /var/www/MISP/app/webroot/img/custom

# Enable and start your mysql database server
sudo systemctl enable mariadb.service
sudo systemctl start  mariadb.service

# Additionally, it is probably a good idea to make the database server listen on localhost only
sudo sh -c 'echo [mysqld] > /etc/my.cnf.d/bind-address.cnf'
sudo sh -c 'echo bind-address=127.0.0.1 >> /etc/my.cnf.d/bind-address.cnf'
sudo systemctl restart mariadb.service

# Add the misp user and database
# may need to add the grant usage from below...not sure though
mysql -u root -e "CREATE DATABASE misp;"
# moved to end mysql -u root -e "GRANT ALL PRIVILEGES ON misp.* TO 'misp'@'localhost' IDENTIFIED BY 'changeme';"
mysql -u root -e "FLUSH PRIVILEGES;"

# Enter the mysql shell <- historical
# sudo mysql -u root -p

# MariaDB [(none)]> create database misp;
# MariaDB [(none)]> grant usage on *.* to misp@localhost identified by 'XXXXXXXXX';
# MariaDB [(none)]> grant all privileges on misp.* to misp@localhost;
# MariaDB [(none)]> exit

cd /var/www/MISP

# Import the empty MySQL database from MYSQL.sql
mysql -u root misp < INSTALL/MYSQL.sql

# Final MySQL config
sudo cp /var/www/MISP/INSTALL/apache.misp.centos7 /etc/httpd/conf.d/misp.conf

# Since SELinux is enabled, we need to allow httpd to write to certain directories
sudo chcon -t httpd_sys_rw_content_t /var/www/MISP/app/files
sudo chcon -t httpd_sys_rw_content_t /var/www/MISP/app/files/terms
sudo chcon -t httpd_sys_rw_content_t /var/www/MISP/app/files/scripts/tmp
sudo chcon -t httpd_sys_rw_content_t /var/www/MISP/app/Plugin/CakeResque/tmp
sudo chcon -R -t httpd_sys_rw_content_t /var/www/MISP/app/tmp
sudo chcon -R -t httpd_sys_rw_content_t /var/www/MISP/app/webroot/img/orgs
sudo chcon -R -t httpd_sys_rw_content_t /var/www/MISP/app/webroot/img/custom

# Allow httpd to connect to the redis server and php-fpm over tcp/ip
sudo setsebool -P httpd_can_network_connect on

# Enable and start the httpd service
sudo systemctl enable httpd.service
sudo systemctl start  httpd.service

# Firewall config
sudo firewall-cmd --add-port=80/tcp --permanent
sudo firewall-cmd --reload

# MISP saves the stdout and stderr of it's workers in /var/www/MISP/app/tmp/logs
# To rotate these logs install the supplied logrotate script:
sudo cp INSTALL/misp.logrotate /etc/logrotate.d/misp

# Now make logrotate work under SELinux as well
# Allow logrotate to modify the log files
sudo semanage fcontext -a -t httpd_log_t "/var/www/MISP/app/tmp/logs(/.*)?"
sudo chcon -R -t httpd_log_t /var/www/MISP/app/tmp/logs

# Allow logrotate to read /var/www
checkmodule -M -m -o /tmp/misplogrotate.mod INSTALL/misplogrotate.te
semodule_package -o /tmp/misplogrotate.pp -m /tmp/misplogrotate.mod
sudo semodule -i /tmp/misplogrotate.pp

# There are 4 sample configuration files in /var/www/MISP/app/Config that need to be copied
cd /var/www/MISP/app/Config
sudo cp -a bootstrap.default.php bootstrap.php
sudo cp -a database.default.php database.php
sudo cp -a core.default.php core.php
sudo cp -a config.default.php config.php

####### autobuild works to here 7/18

# Configure the fields in the newly created files:
# Need to sed the shit out of this
# config.php   : baseurl (example: 'baseurl' => 'http://misp',) - don't use "localhost" it causes issues when browsing externally
# config.php   : salt - change this to something new
# config.php   : email - set an email address here, you'll need it to match your GPG config later on
# core.php   : Uncomment and set the timezone: `date_default_timezone_set('UTC');`
# core.php  : change "Vendor/autoload.php" to "vendor/autoload.php" <- this needs a PR or maybe this is a product of the checkouts that I'm skipping?
# database.php : login, port, password, database
# class DATABASE_CONFIG {
#   public $default = array(
#       'datasource' => 'Database/Mysql',
#       'persistent' => false,
#       'host' => 'localhost',
#       'login' => 'misp',
#       'port' => 3306,
#       'password' => 'XXXXdbpasswordhereXXXXX',
#       'database' => 'misp',
#       'prefix' => '',
#       'encoding' => 'utf8',
#   );
#}

# Important note on the salt key you changed in "config.php"
# The admin user account will be generated on the first login, make sure that the salt is changed before you create that user
# If you forget to do this step, and you are still dealing with a fresh installation, just alter the salt,
# delete the user from mysql and log in again using the default admin credentials (admin@admin.test / admin)

# If you want to be able to change configuration parameters from the webinterface:
sudo chown apache:apache /var/www/MISP/app/Config/config.php
sudo chcon -t httpd_sys_rw_content_t /var/www/MISP/app/Config/config.php

# Generate a GPG encryption key.
# If the following command gives an error message, try it as root from the console
gpg --gen-key
sudo mv ~/.gnupg /var/www/MISP/
sudo chown -R apache:apache /var/www/MISP/.gnupg

# And export the public key to the webroot
sudo sh -c 'sudo -u apache gpg --homedir /var/www/MISP/.gnupg --export --armor contact@misp.com > /var/www/MISP/app/webroot/gpg.asc'

# Start the workers to enable background jobs
sudo chmod +x /var/www/MISP/app/Console/worker/start.sh
sudo su -s /bin/bash apache -c 'scl enable rh-php56 /var/www/MISP/app/Console/worker/start.sh'

# To make the background workers start on boot
sudo vi /etc/rc.local
# Add the following line at the end
su -s /bin/bash apache -c 'scl enable rh-php56 /var/www/MISP/app/Console/worker/start.sh'
# and make sure it will execute
sudo chmod +x /etc/rc.local

# Make sure the permissions are set correctly
sudo chown -R root:apache /var/www/MISP
sudo find /var/www/MISP -type d -exec chmod g=rx {} \;
sudo chmod -R g+r,o= /var/www/MISP
sudo chown apache:apache /var/www/MISP/app/files
sudo chown apache:apache /var/www/MISP/app/files/terms
sudo chown apache:apache /var/www/MISP/app/files/scripts/tmp
sudo chown apache:apache /var/www/MISP/app/Plugin/CakeResque/tmp
sudo chown -R apache:apache /var/www/MISP/app/tmp
sudo chown -R apache:apache /var/www/MISP/app/webroot/img/orgs
sudo chown -R apache:apache /var/www/MISP/app/webroot/img/custom

# Secure MySQL
mysql -u root -e "GRANT ALL PRIVILEGES ON misp.* TO 'misp'@'localhost' IDENTIFIED BY 'changeme';"
sudo mysql_secure_installation

# Now log in using the webinterface: http://misp/users/login
# The default user/pass = admin@admin.test/admin

# Using the server settings tool in the admin interface (Administration -> Server Settings), set MISP up to your preference
# It is especially vital that no critical issues remain!

# Don't forget to change the email, password and authentication key after installation.

# Once done, have a look at the diagnostics

# If any of the directories that MISP uses to store files is not writeable to the apache user, change the permissions
# you can do this by running the following commands:

chmod -R 750 /var/www/MISP/<directory path with an indicated issue>
chown -R apache:apache /var/www/MISP/<directory path with an indicated issue>

# Make sure that the STIX libraries and GnuPG work as intended, if not, refer to INSTALL.txt's paragraphs dealing with these two items

# If anything goes wrong, make sure that you check MISP's logs for errors:
# /var/www/MISP/app/tmp/logs/error.log
# /var/www/MISP/app/tmp/logs/resque-worker-error.log
# /var/www/MISP/app/tmp/logs/resque-scheduler-error.log
# /var/www/MISP/app/tmp/logs/resque-2015-01-01.log //where the actual date is the current date

# Recommended actions
# - By default CakePHP exposes his name and version in email headers. Apply a patch to remove this behavior.
# - You should really harden your OS
# - You should really harden the configuration of Apache
# - You should really harden the configuration of MySQL
# - Keep your software up2date (MISP, CakePHP and everything else)
# - Log and audit

echo "See the "Build, Operate, Maintain" document of the capesstack/capes/misp repository on GitHub."
