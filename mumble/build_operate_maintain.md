# Mumble Build, Operate, Maintain

## Build
After either running the [CAPES deployment script](../deploy_capes.sh) or the [independent Mumble deployment script](deploy_mumble.sh), you'll need to configure some environment variables to complete the installation and prepare for usage.

Everything in the Build phase is done with either the deploy_capes.sh or deploy_mumble.sh script, the below steps are only if you are doing this completely manually.

### Prepare the Environment
```
sudo yum -y install bzip2 && yum -y update
sudo groupadd -r murmur
sudo useradd -r -g murmur -m -d /var/lib/murmur -s /sbin/nologin murmur
sudo mkdir -p /var/log/murmur
sudo chown murmur:murmur /var/log/murmur
sudo chmod 0770 /var/log/murmur
```

### Download Binaries
```
curl -OL https://github.com/mumble-voip/mumble/releases/download/1.2.19/murmur-static_x86-1.2.19.tar.bz2
tar vxjf murmur-static_x86-1.2.19.tar.bz2
sudo mkdir -p /opt/murmur
sudo cp -r ./murmur-static_x86-1.2.19/* /opt/murmur
sudo cp ./murmur-static_x86-1.2.19/murmur.ini /etc/murmur.ini
```
#### Note
Check the version you're downloading to make sure it's `1.2.19`. If it isn't, you'll need to make sure you adjust the file names in the instructions above.

### Configure /etc/murmur.ini
Make sure that the following settings are properly configured in
```
sudo vi /etc/murmur.ini
database=/var/lib/murmur/murmur.sqlite
registerName=CAPES - Mumble Server
logfile=/var/log/murmur/murmur.log
pidfile=/var/run/murmur/murmur.pid
port=7000
```

### Configure the Firewall
```
sudo firewall-cmd --add-port=7000/tcp --add-port=7000/udp --permanent
sudo firewall-cmd --reload
```

### Rotate Logs
To avoid `/var/log` filling up, let's set up a log rotation
```
sudo vi /etc/logrotate.d/murmur
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
```

### Creating the systemd Service
We want this to run in the background and at boot, so...
```
sudo vi /etc/systemd/system/murmur.service
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
```
### Generate the `/var/run` pid Directory
```
sudo vi /etc/tmpfiles.d/murmur.conf
d /var/run/murmur 775 murmur murmur
```

### Prepare the Execution Environment
```
sudo systemd-tmpfiles --create /etc/tmpfiles.d/murmur.conf
sudo systemctl daemon-reload
sudo systemctl enable murmur.service
```

## Operate
### Run the Service
Let's fire this puppy up!
```
sudo systemctl start murmur.service
```

### Configure the SuperUser Account
```
sudo /opt/murmur/murmur.x86 -ini /etc/murmur.ini -supw <passphrase>
```

### Connect to the Mumble Server
1. Download the client of your choosing from the [Mumble client page](https://www.mumble.com/mumble-download.php)
1. Install
1. There will be considerable menus to navigate, just accept the defaults unless you have a reason not to and need a custom deployment.
1. Start it up and connect to
  1. Label: Whatever you want your channel to be called...maybe "CAPES" or something?
  1. Address: CAPES server IP address
  1. Port: 7000
  1. Username: whatever you want
  1. Password: this CAN be blank...but it shouldn't be **ahem**
  1. Click "OK"
  1. Select the channel you just created and click "Connect"
1. Right click on your name and select "Register"

### Delegating Permissions
Once a user has created an account and Registered, you can add them to the `admin` role.

1. Click on the Globe and select the channel that you created and click "Edit"
1. For the username, use the `SuperUser` account with the passphrase you set during installation (the passphrase box will show up once you type `SuperUser`).
1. Right-click on main channel (likely "CAPES - Mumble Server") and select `Edit`
1. Go to the Groups tab
1. Select the `admin` role from the drop down
1. Type the user account you want to delegate admin functions to in the box
1. Click `Add` and then `Ok`
1. Click on the Globe and select the channel that you created and click "Edit"
1. Enter your username (not `SuperUser`) and your passphrase, and you can log in and perform administrative functions

### Creating Channels
1. Right-click on the main channel (likely "CAPES - Mumble Server") and select `Add`
1. Name and add the channel

#### Note
If the `Temporary` box is checked and greyed out, you do not have not been delegated rights. See [Delegating Permissions](#delegating-permissions) above.

## Additional documentation  
https://wiki.mumble.info/wiki/
https://wiki.mumble.info/wiki/Murmurguide
