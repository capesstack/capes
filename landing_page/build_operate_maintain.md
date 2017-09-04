# CAPES Land Page Build, Operate, Maintain
This will distill the basic installation and configuration of the HTTP server, nginx, as it relates to the CAPES project.

Yes, believe me, I know there are a lot of ways to do this, and that when you're running more than 1 web service, there are individual `.conf` files to use - I get it :) That said, as it relates to CAPES, we only need a single `index.html` page and just allow `nginx` to do it's thing there without making a configuration file for the entire CAPES web application. I'm certainly open to reasons to do this in a more complex way, but as it sits right now, I didn't see the need. PR and Issues are gleefully welcome.

For additional configuration and deployment options, see the official [nginx wiki](https://www.nginx.com/resources/wiki/).

## Build

### Dependencies
Below are the dependencies for the CAPES landing page. These are installed using the `deploy_landing_page.sh` or the `deploy_capes.sh` scripts.

| Package      | Version           |
|--------------|-------------------|
| epel-release | 7-9               |
| git          | 1.0.3.1-6.el7_2.1 |
| nginx        | 1:1.10.2-1.el7    |

### Server Build
Please see the [server build instructions](../docs/README.md#build-your-os).

### Installation
Run the [CAPES deployment script](../deploy_capes.sh) or the [independent Landing Page deployment script](deploy_landing_page.sh).

Deploying with CAPES (recommended):
```
$ sudo yum install -y git
$ git clone https://github.com/capesstack/capes.git
$ cd capes
$ sudo sh deploy_capes.sh
```
Deploying separately from CAPES:
```
$ sudo yum install -y git
$ git clone https://github.com/capesstack/capes.git
$ cd capes/landing_page
$ sudo sh deploy_landing_page.sh
```
## Operate

### Firewall Ports
The firewall is controlled through the `firewalld` service. It is started by default if you used the proper [server build instructions](../docs/README.md#build-your-os).

#### Opening Firewall Ports
TCP port 80 is needed to access the CAPES landing page, and it is included in the `deploy_landing_page.sh` script, however:
```
$ sudo firewall-cmd --add-port=80/tcp --permanent
$ sudo firewall-cmd --reload
```

#### Checking Firewall Ports
Again, you shouldn't need to monkey with the firewall ports, but for completeness:
```
$ sudo firewall-cmd --list-all
drop (active)
target: DROP
icmp-block-inverstion: no
interfaces: ens33 (this could be different)
sources:
services:
ports: 80/tcp
protocols:
masquerade: no
forward-ports:
sourceports:
icmp-blocks:
rich rules:
```

### Services
The service is `nginx.service` and it is controlled as followed using `systemd`.

#### nginx
##### Starting
To start the nginx service
```
$ sudo systemctl start nginx.service
```
##### Stopping
To stop the nginx service
```
$ sudo systemctl stop nginx.service
```
##### Restarting
To restart the nginx service
```
$ sudo systemctl restart nginx.service
```
Of note, if you make updates to your nginx configuration, you don't need to restart the service. You can use `$ sudo nginx -s reload` to send the reload signal and refresh the running config.

#### firewalld
##### Starting
To start the firewalld service
```
$ sudo systemctl start firewalld.service
```
##### Stopping
To stop the firewalld service
```
$ sudo systemctl stop firewalld.service
```
##### Restarting
To restart the firewalld service
```
$ sudo systemctl restart firewalld.service
```
Of note, if you make updates to your firwall configuration, you don't need to restart the service. You can use `$ sudo firewall-cmd --reload` to refresh the running config.

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
