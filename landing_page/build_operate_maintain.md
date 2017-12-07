# CAPES Land Page Build, Operate, Maintain
The CAPES landing page was developed to give a singular place for operators to go to access all of the CAPES toolsets. Feel free to customize it to meet your environment. The only exception to this is Mumble as it is not a web application.

**This will distill the basic installation and configuration of the HTTP server, nginx, as it relates to the CAPES project.**

**Yes, believe me, I know there are a lot of ways to do this, and that when you're running more than 1 web service, there are individual `.conf` files to use - I get it :) That said, as it relates to CAPES, we only need a single `index.html` page and just allow `nginx` to do it's thing there without making a configuration file for the entire CAPES web application. I'm certainly open to reasons to do this in a more complex way, but as it sits right now, I didn't see the need. PR and Issues are gleefully welcome.**

**For additional configuration and deployment options, see the official [nginx wiki](https://www.nginx.com/resources/wiki/).**

## Build

### Dependencies
Below are the dependencies for the CAPES landing page. These are installed using the `deploy_landing_page.sh` or the `deploy_capes.sh` scripts.

| Package      | Version           |
|--------------|-------------------|
| epel-release | 7-10              |
| git          | 1.8.3.1-12.el7_4  |
| nginx        | 1:1.10.2-1.el7    |

### Server Build
Please see the [server build instructions](../docs/README.md#build-your-os).

### Installation
Run the [CAPES deployment script](../deploy_capes.sh) or the [independent Landing Page deployment script](deploy_landing_page.sh).

Deploying with CAPES (recommended):
```
sudo yum install -y git
git clone https://github.com/capesstack/capes.git
cd capes
sudo sh deploy_capes.sh
```
Deploying separately from CAPES:
```
sudo yum install -y git
git clone https://github.com/capesstack/capes.git
cd capes/landing_page
sudo sh deploy_landing_page.sh
```
## Operate
The landing page runs as the `nginx` user, it has no shell and cannot be logged on as.

### Authentication
CAPES employs Basic Auth for logging into the landing page. The passphrase is set during installation for the user "operator".

If you need reset the credentials for the user "operator":
```
sudo htpasswd /etc/nginx/.htpasswd operator
```
If you need to create new users:
```
sudo htpasswd /etc/nginx/.htpasswd <new_user>
```

### Cosmetics
There is an included `favicon.ico` file for the little image that shows up on browser tabs, you can update this with your own logo in `/usr/share/nginx/html/favicon.ico`. Its dimensions should be `32x32`.

To update the `Your Logo Here` graphic, place your logo in the `/usr/share/nginx/html/images` directory. Its dimensions should be `250x250`. You will also need to update `/usr/share/nginx/html/index.html` with the logo name:
```
sudo sed -i 's/your-logo.png/<your-actual-logo-name-with-extension>/' /usr/share/nginx/html/index.html
```
### Services
There are multiple service presented by the CAPES landing page.
* [CyberChef](../cyberchef/build_operate_maintain.md)
* [Etherpad](../etherpad/build_operate_maintain.md)  
* [Gitea](../gitea/build_operate_maintain.md)  
* [Rocketchat](../rocketchat/build_operate_maintain.md)  
* [TheHive](../thehive/build_operate_maintain.md)  
* [Cortex](../thehive/build_operate_maintain.md)  

## Maintain
You can make changes to the nginx configuration or update your environment as necessary.

### Package Locations
CAPES nginx landing page location - `/usr/share/nginx/html/index.html`   
nginx main configuration location - `/etc/nginx/nginx.conf`

### Update Configuration
If you update the nginx configuration, you'll need to reload nginx by sending the `reload` signal.
```
$ sudo nginx -s reload
```

### Update nginx
If you need to update the nginx package:
```
$ sudo yum update nginx
```

## Troubleshooting
In the event that you have any issues, here are some things you can check to make sure they're operating as intended.

Is the site accessible locally?
```
curl localhost
curl: (7) Failed connect to capes:80; Connection refused
```
This appears to indicate that nginx may not be running.

### nginx Service
Obviously nginx needs to be running to display the web application. If the site isn't accessible ensure that nginx is running.
```
sudo systemctl status nginx.service
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
   Active: active (running) since Sun 2017-09-17 11:24:07 EDT; 1min 40s ago
  Process: 14698 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 14695 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 14693 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 14700 (nginx)
   CGroup: /system.slice/nginx.service
           ├─14700 nginx: master process /usr/sbin/nginx
           ├─14701 nginx: worker process
           ├─14702 nginx: worker process
           ├─14703 nginx: worker process
           └─14704 nginx: worker process

● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
   Active: inactive (dead) since Sun 2017-09-17 11:28:33 EDT; 6min ago
 Main PID: 14700 (code=exited, status=0/SUCCESS)
```
If `nginx` shows `Active: inactive (dead)` let's try to start the service.
```
sudo systemctl start nginx.service
```
While the deployment script will set nginx to start on boot, you may want to check to make sure:
```
ls /usr/lib/systemd/system/ | grep nginx.service
```
If you don't get `nginx.service` as a response, nginx isn't set to start on boot. Correct this:
```
sudo systemctl enable nginx.service
```
Let's check to see if we're making progress, and hopefully you'll see:
```
curl localhost
<!DOCTYPE html>
	<head>
	<meta charset="utf-8">
	<meta http-equiv="X-UA-Compatible" content="IE=edge">
	<title>CAPES Landing Page</title>
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<meta name="description" content="Cyber Analytics Platform and Examination System landing page." />
  ...
```
If you're still unable to access CAPES via a web browser, let's move onto checking the firewall.

### Firewall Ports
The firewall is controlled through the `firewalld` service. It is started by default if you used the proper [server build instructions](../docs/README.md#build-your-os).

#### Checking Firewall Ports
Let's check to make sure that port 80 is open:
```
$ sudo firewall-cmd --list-all
drop (active)
target: DROP
icmp-block-inverstion: no
interfaces: ens33 (this could be different)
sources:
services: ssh
ports: 80/tcp
protocols:
masquerade: no
forward-ports:
sourceports:
icmp-blocks:
rich rules:
```
If port 80 isn't listed, then we'll need to open that up.

#### Opening Firewall Ports
TCP port 80 is needed to access the CAPES landing page, and it is included in the `deploy_landing_page.sh` script, however:
```
sudo firewall-cmd --add-port=80/tcp --permanent
sudo firewall-cmd --reload
```
If you're still unable to access the CAPES page from a web browser, [please file an issue](https://github.com/capesstack/capes/issues).
