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

# All of these call to be done as root, I'm trying sudo, but let's see how it works.

1/ Minimal CentOS install
-------------------------

Install a minimal CentOS 7.x system with the software:

# Make sure you set your hostname CORRECTLY vs. like an animal (manually in /etc/hostname)
hostnamectl set-hostname misp # or whatever you want it to be

# Set your time to UTC, this is crucial. If you have already set your time in accordance with your local standards, you may comment this out.
# If you're not using UTC, I strongly recommend reading this: http://yellerapp.com/posts/2015-01-12-the-worst-server-setup-you-can-make.html
timedatectl set-timezone UTC

# Make sure your system is up2date:
yum update -y

2/ Dependencies *
----------------
Once the system is installed you can perform the following steps as root:

# We need some packages from the Extra Packages for Enterprise Linux repository
yum install epel-release -y

# Since MISP 2.4 PHP 5.5 is a minimal requirement, so we need a newer version than CentOS base provides
# Software Collections is a way do to this, see https://wiki.centos.org/AdditionalResources/Repositories/SCL
yum install centos-release-scl -y

# Install the dependencies:
yum install gcc git httpd zip redis mariadb mariadb-server python-devel python-pip libxslt-devel zlib-devel rh-php56 rh-php56-php-fpm rh-php56-php-devel rh-php56-php-mysqlnd rh-php56-php-mbstring rh-php56-php-xml rh-php56-php-bcmath php-redis -y

# Start rh-php56-php-fpm
systemctl enable rh-php56-php-fpm.service
systemctl start  rh-php56-php-fpm.service

# Start a new shell with rh-php56 enabled
scl enable rh-php56 bash

pear channel-update pear.php.net

pear install Crypt_GPG

# GPG needs lots of entropy, haveged provides entropy
yum install haveged -y
systemctl enable haveged.service
systemctl start  haveged.service

# Enable and start redis
systemctl enable redis.service
systemctl start  redis.service

3/ MISP code
------------
# Download MISP using git in the /var/www/ directory.
cd /var/www/
git clone https://github.com/MISP/MISP.git
cd /var/www/MISP
git checkout tags/$(git describe --tags `git rev-list --tags --max-count=1`)
# if the last shortcut doesn't work, specify the latest version manually
# example: git checkout tags/v2.4.XY
# the message regarding a "detached HEAD state" is expected behaviour
# (you only have to create a new branch, if you want to change stuff and do a pull request for example)

# Make git ignore filesystem permission differences
git config core.filemode false

# install Mitre's STIX and its dependencies by running the following commands:
pip install --upgrade pip
pip install importlib
yum install python-lxml python-dateutil python-six -y
cd /var/www/MISP/app/files/scripts
git clone https://github.com/CybOXProject/python-cybox.git
git clone https://github.com/STIXProject/python-stix.git
cd /var/www/MISP/app/files/scripts/python-cybox
git checkout v2.1.0.12
git config core.filemode false
python setup.py install
cd /var/www/MISP/app/files/scripts/python-stix
git checkout v1.1.1.4
git config core.filemode false
python setup.py install

# install mixbox to accomodate the new STIX dependencies:
cd /var/www/MISP/app/files/scripts/
git clone https://github.com/CybOXProject/mixbox.git
cd /var/www/MISP/app/files/scripts/mixbox
git checkout v1.0.2
git config core.filemode false
python setup.py install

4/ CakePHP
-----------
cd /var/www/MISP
git submodule init
git submodule update

# Once done, install CakeResque along with its dependencies if you intend to use the built in background jobs:
cd /var/www/MISP/app
php composer.phar require kamisama/cake-resque:4.1.2
php composer.phar config vendor-dir Vendor
php composer.phar install
pecl install redis-2.2.8
echo "extension=redis.so" > /etc/opt/rh/rh-php56/php-fpm.d/redis.ini
ln -s ../php-fpm.d/redis.ini /etc/opt/rh/rh-php56/php.d/99-redis.ini
systemctl restart rh-php56-php-fpm.service

# If you have not yet set a timezone in php.ini
# You can get a list of available timezones through "timedatectl list-timezones"
echo 'date.timezone = "UTC"' > /etc/opt/rh/rh-php56/php-fpm.d/timezone.ini
ln -s ../php-fpm.d/timezone.ini /etc/opt/rh/rh-php56/php.d/99-timezone.ini

# To use the scheduler worker for scheduled tasks, do the following:
cp -fa /var/www/MISP/INSTALL/setup/config.php /var/www/MISP/app/Plugin/CakeResque/Config/config.php

5/ Set the permissions
----------------------

# Make sure the permissions are set correctly using the following commands as root:
chown -R root:apache /var/www/MISP
find /var/www/MISP -type d -exec chmod g=rx {} \;
chmod -R g+r,o= /var/www/MISP
chown apache:apache /var/www/MISP/app/files
chown apache:apache /var/www/MISP/app/files/terms
chown apache:apache /var/www/MISP/app/files/scripts/tmp
chown apache:apache /var/www/MISP/app/Plugin/CakeResque/tmp
chown -R apache:apache /var/www/MISP/app/tmp
chown -R apache:apache /var/www/MISP/app/webroot/img/orgs
chown -R apache:apache /var/www/MISP/app/webroot/img/custom

6/ Create a database and user
-----------------------------
# Enable, start and secure your mysql database server
systemctl enable mariadb.service
systemctl start  mariadb.service
mysql_secure_installation

# Additionally, it is probably a good idea to make the database server listen on localhost only
echo [mysqld] > /etc/my.cnf.d/bind-address.cnf
echo bind-address=127.0.0.1 >> /etc/my.cnf.d/bind-address.cnf
systemctl restart mariadb.service

# Enter the mysql shell
mysql -u root -p

MariaDB [(none)]> create database misp;
MariaDB [(none)]> grant usage on *.* to misp@localhost identified by 'XXXXXXXXX';
MariaDB [(none)]> grant all privileges on misp.* to misp@localhost ;
MariaDB [(none)]> exit

cd /var/www/MISP

# Import the empty MySQL database from MYSQL.sql
mysql -u misp -p misp < INSTALL/MYSQL.sql


7/ Apache configuration
-----------------------
# Now configure your apache server with the DocumentRoot /var/www/MISP/app/webroot/
# A sample vhost can be found in /var/www/MISP/INSTALL/apache.misp.centos7

cp /var/www/MISP/INSTALL/apache.misp.centos7 /etc/httpd/conf.d/misp.conf

# Since SELinux is enabled, we need to allow httpd to write to certain directories
chcon -t httpd_sys_rw_content_t /var/www/MISP/app/files
chcon -t httpd_sys_rw_content_t /var/www/MISP/app/files/terms
chcon -t httpd_sys_rw_content_t /var/www/MISP/app/files/scripts/tmp
chcon -t httpd_sys_rw_content_t /var/www/MISP/app/Plugin/CakeResque/tmp
chcon -R -t httpd_sys_rw_content_t /var/www/MISP/app/tmp
chcon -R -t httpd_sys_rw_content_t /var/www/MISP/app/webroot/img/orgs
chcon -R -t httpd_sys_rw_content_t /var/www/MISP/app/webroot/img/custom

# Allow httpd to connect to the redis server and php-fpm over tcp/ip
setsebool -P httpd_can_network_connect on

# Enable and start the httpd service
systemctl enable httpd.service
systemctl start  httpd.service

# Open a hole in the iptables firewall
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --reload

# We seriously recommend using only HTTPS / SSL !
# Add SSL support by running: yum install mod_ssl
# Check out the apache.misp.ssl file for an example

8/ Log rotation
---------------
# MISP saves the stdout and stderr of it's workers in /var/www/MISP/app/tmp/logs
# To rotate these logs install the supplied logrotate script:

cp INSTALL/misp.logrotate /etc/logrotate.d/misp

# Now make logrotate work under SELinux as well
# Allow logrotate to modify the log files
semanage fcontext -a -t httpd_log_t "/var/www/MISP/app/tmp/logs(/.*)?"
chcon -R -t httpd_log_t /var/www/MISP/app/tmp/logs

# Allow logrotate to read /var/www
checkmodule -M -m -o /tmp/misplogrotate.mod INSTALL/misplogrotate.te
semodule_package -o /tmp/misplogrotate.pp -m /tmp/misplogrotate.mod
semodule -i /tmp/misplogrotate.pp

9/ MISP configuration
---------------------
# There are 4 sample configuration files in /var/www/MISP/app/Config that need to be copied
cd /var/www/MISP/app/Config
cp -a bootstrap.default.php bootstrap.php
cp -a database.default.php database.php
cp -a core.default.php core.php
cp -a config.default.php config.php

# Configure the fields in the newly created files:
# config.php   : baseurl (example: 'baseurl' => 'http://misp',) - don't use "localhost" it causes issues when browsing externally
# config.php   : salt - change this to something new
# config.php   : email - set an email address here, you'll need it to match your GPG config later on
# core.php   : Uncomment and set the timezone: `date_default_timezone_set('UTC');`
# database.php : login, port, password, database
# DATABASE_CONFIG has to be filled
# With the default values provided in section 6, this would look like:
# class DATABASE_CONFIG {
#   public $default = array(
#       'datasource' => 'Database/Mysql',
#       'persistent' => false,
#       'host' => 'localhost',
#       'login' => 'misp', // grant usage on *.* to misp@localhost
#       'port' => 3306,
#       'password' => 'XXXXdbpasswordhereXXXXX', // identified by 'XXXXdbpasswordhereXXXXX';
#       'database' => 'misp', // create database misp;
#       'prefix' => '',
#       'encoding' => 'utf8',
#   );
#}

# Important note on the salt key you changed in "config.php"
# The admin user account will be generated on the first login, make sure that the salt is changed before you create that user
# If you forget to do this step, and you are still dealing with a fresh installation, just alter the salt,
# delete the user from mysql and log in again using the default admin credentials (admin@admin.test / admin)

# If you want to be able to change configuration parameters from the webinterface:
chown apache:apache /var/www/MISP/app/Config/config.php
chcon -t httpd_sys_rw_content_t /var/www/MISP/app/Config/config.php

# Generate a GPG encryption key.
# If the following command gives an error message, try it as root from the console
gpg --gen-key
mv ~/.gnupg /var/www/MISP/
chown -R apache:apache /var/www/MISP/.gnupg

# The email address should match the one set in the config.php configuration file
# Make sure that you use the same settings in the MISP Server Settings tool (Described on line 246)

# And export the public key to the webroot
sudo -u apache gpg --homedir /var/www/MISP/.gnupg --export --armor <email address from gpg & config.php> > /var/www/MISP/app/webroot/gpg.asc

# Start the workers to enable background jobs
chmod +x /var/www/MISP/app/Console/worker/start.sh
su -s /bin/bash apache -c 'scl enable rh-php56 /var/www/MISP/app/Console/worker/start.sh'

# To make the background workers start on boot
vi /etc/rc.local
# Add the following line at the end
su -s /bin/bash apache -c 'scl enable rh-php56 /var/www/MISP/app/Console/worker/start.sh'
# and make sure it will execute
chmod +x /etc/rc.local

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

Recommended actions
-------------------
- By default CakePHP exposes his name and version in email headers. Apply a patch to remove this behavior.

- You should really harden your OS
- You should really harden the configuration of Apache
- You should really harden the configuration of MySQL
- Keep your software up2date (MISP, CakePHP and everything else)
- Log and audit
