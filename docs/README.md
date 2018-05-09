# Documentation
Please see below for Build, Operate, Maintain specifics on the different web applications
* [Post Installation](https://github.com/capesstack/capes/tree/master/docs#post-installation)
* [CAPES Landing Page](../landing_page/build_operate_maintain.md)  
* [CyberChef](../cyberchef/build_operate_maintain.md)
* [Gitea](../gitea/build_operate_maintain.md)  
* [Mattermost](../mattermost/build_operate_maintain.md)  
* [TheHive](../thehive/build_operate_maintain.md)  
* [Cortex](../thehive/build_operate_maintain.md)  
* [Mumble](../mumble/build_operate_maintain.md)  
* [Kibana](../kibana/build_operate_maintain.md)
* [Beats (Elastic's Heartbeat & Metricbeat)](../beats/build_operate_maintain.md)

## Requirements
There has not been extensive testing, but all of these services have run without issue on a single virtual machine with approximately 20 users and no issue for a week. That said, your mileage may vary.

While the OS version isn't a hard requirement, all testing and development work has been done with `CentOS 7.4.1708 (Core)`.

| Component | Number |
| - | - |
| Cores | 4 |
| RAM | 8 GB |
| Hard Disk | 20 GB |

## Secure by Design

### Secure Deployment
There is an inherent risk to deploying web applications to the Internet or to a contested networking enclave -- basically, somewhere the bad guys can get to.

To address this, the CAPES project has done a few things to help protect these web applications and left a few things for you, the operator, to close in on as your need requires.

### Operating System
While there are a lot of projects that are developed using Ubuntu (many of these service creators still follow that path), CAPES chose to use CentOS because of a few different reasons:  
1. CentOS is the open source version of Red Hat Enterprise Linux (RHEL)
    - Many enterprises use RHEL as their Linux distribution of choice because you can purchase support for it
    - We wanted to use a distribution that could easily be ported from an open source OS to the supported OS (RHEL)
1. CentOS uses Security Enhanced Linux (SELinux) instead of AppArmor
    - SELinux uses context to define security controls (for example, I know a text editor shouldn't talk to the Internet because it's a text editor, not a browser)
    - AppArmor uses prescripted rules to define security controls (for example, I know that a text editor shouldn't talk to the Internet because someone told me it shouldn't)

### Implementation
While the `firewalld` service is running on CAPES and the only ports listening have services attached to them, you should still consider using a Web Application Firewall (WAF), an Intrusion Detection System (IDS) or a Network Security Monitor (like [ROCKNSM](rocknsm.io) - which has an IDS integrated on top of a litany of other goodies) to ensure that your CAPES stack isn't being targeted.

If possible, CAPES, just like a passive NSM, should **not** be on the contested network. This will prevent it from being targeted by aggressors.

### SSL
It is a poor practice to deploy self-signed SSL certificates because it teaches bad behavior by "clicking through" SSL warnings; for that reason, we have decided not to deploy CAPES with SSL. [If you want to enable SSL for your own deployment](https://nginx.org/en/docs/http/configuring_https_servers.html), we encourage you to do so.

## Installation
Generally, the CAPES ecosystem is meant to run as a whole, so the preferred usage will be to install CAPES with the `deploy_capes.sh` script in the root directory of this repository. Additionally, if there is a service that you do not want, you can comment that service out of the deploy script as they are documented with service headers.

That said, there is a deploy script for each of the services that you should be able to run individually if your use case requires that.

### Build your OS (CentOS 7.4)
This is meant to help those who need a step-by-step build of CentOS, securing SSh, and getting ready to grab CAPES. If you don't need this guide, skip on down to [Get CAPES](#get-capes).
1. Download the latest version of [CentOS Minimal](http://isoredirect.centos.org/centos/7/isos/x86_64/CentOS-7-x86_64-Minimal-1611.iso)
1. Build a VM or a physical system with 4 cores, 8 GB of RAM, and a 20 GB HDD at a minimum
    - Don't use any of the "easy install" options when setting up a VM, we're going to make some config changes in the build process
    - I recommend removing all the things that get attached that you're not going to use (speakers, BlueTooth, USB, printer support, floppy, web camera, etc.)
1. Fire up the VM and boot into Anaconda (the Linux install wizard)
1. Select your language
1. Start at the bottom-left, `Network & Host Name`
    - There is the `Host Name` box at the bottom of the window, you can enter a hostname here or we can do that later...in either case, `localhost` is a poor choice
    - Switch the toggle to enable your NIC
      - Click `Configure`
      - Go to `IPv6 Settings` and change from `Automatic` to `Ignore`
      - Click `Save`
    - Click `Done` in the top left
1. Next the `Security Profile` in the lower right
    - Select `United States Government Configuration Baseline (USGCB/STIG) - DRAFT`
    - Click `Select Profile`
    - Click `Done`
1. Next click `Installation Destination`
    - Select the hard disk you want to install CentOS to, likely it is already selected unless you have more than 1 drive
    - Click `Done`
1. Click `kdump`
    - Uncheck `Enable kdump`
    - Click `Done`
1. `Installation Source` should say `Local media` and `Software Selection` should say `Minimal install` - no need to change this
1. Click `Date & Time`
    - `Region` should be changed to `Etc`
    - `City` should be changed to `Coordinated Universal Time`
    - `Network Time` should be toggled on
    - Click `Done`
    - Note - the beginning of these install scripts configures Network Time Protocol (NTP). You just did that, but it's included just to be safe because time, and DNS, matter.
1. Click `Begin Installation`
1. We're not going to set a Root passphrase because CAPES will never, ever need it. Ever. Not setting a passphrase locks the Root account.
1. Create a user, but ensure that you toggle the `Make this user administrator` checkbox
1. Once the installation is done, click the `Reboot` button in the bottom right to...well...reboot
1. Login using the account you created during the Anaconda setup
  - Run the following commands
    ```
    sudo yum update -y && sudo yum install git -y #(Enter the passphrase you created in Anaconda)
    sudo firewall-cmd --add-service=ssh --permanent
    sudo firewall-cmd --reload
    ```
1. Secure ssh
  - On your management system, create an ssh key pair
    ```
    ssh-keygen -t rsa #accept the defaults, but enter a passphrase for your keys
    ssh-copy-id your_created_user@<ip of CAPES>
    ssh your_created_user@<ip of CAPES>
    sudo sed -i 's/\#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo systemctl restart sshd.service
    ```
## Get CAPES
Finally, here we go.

### CentOS 7.4
```
$ sudo yum -y install git
$ git clone https://github.com/capesstack/capes.git
$ cd capes
$ sudo sh deploy_capes.sh
```

### Pre-CentOS 7.4
```
$ sudo yum install -y https://kojipkgs.fedoraproject.org/packages/http-parser/2.7.1/3.el7/x86_64/http-parser-2.7.1-3.el7.x86_64.rpm
$ sudo yum -y install git
$ git clone https://github.com/capesstack/capes.git
$ cd capes
$ sudo sh deploy_capes.sh
```

### Build Process
The build is automated minus asking you to set the Gitea, CAPES, and Mumble administrative passphrases, set the MariaDB root passphrase, and confirm some security settings for MariaDB.

You'll be asked to create the first three passphrases at the beginning and to create the MariaDB passphrase at the end of the CAPES installation.

This will start the automated build of:
* Configure NTP (likely already done, but in the event you skipped the [Build your OS](#build-your-os) above)
* Install Mattermost
* Install Gitea
* Install TheHive
* Install Cortex
* Install Mumble
* Install CyberChef
* Install Nginx
* Install Kibana (with Elastic's Heartbeat and Metricbeat)
* Install the CAPES landing page
* Secure the MySQL installation
* Make firewall changes
* Set everything to autostart

## Post Installation
While the CAPES deploy script attempts to get you up and running, there are a few things that need to be done after installation.

### Beats
1. Set your MariaDB root passphrase (which you set at the very end of the deployment) in `/etc/metricbeat/metricbeat.yml`, replacing `passphrase_to_be_set_post_install`  
1. Check Filebeat and make sure it's running. If Elasticsearch doesn't start fast enough, Filebeat will fail when trying to connect to it. You can try to simply restart it with `sudo systemctl restart filebeat.service`. If Filebeat won't start )`sudo systemctl status filebeat.service`) you can look at the log file to see what the reason is (`sudo cat /var/log/filebeat/capes_filebeat`)

### Cortex
1. Log into Cortex and create a new Organization and an Organization Administrator, set that user's passphrase
1. Log out and back into Cortex as the new Organization Administrator that you created, click on "Organization" and then click on "Users"
1. Create a user called `TheHiveIntegration` (or the like) with the `read,analyze` roles, create an API key, copy that down

### TheHive
1. Open `/opt/thehive/application.conf` and go to the very bottom of the document and add `key = <your-api-key>` to the `CORTEX-SERVER-ID` section (`your-IP-address` should already be populated). The API key is the one you created above in Cortex.
```
cortex {
  "CORTEX-SERVER-ID" {
  url = "http://<your-IP-address>:9001"
  key = "<your-API-key>"
  }
}
```
1. Restart The Hive with `sudo systemctl restart thehive.service`
1. Collect the Report Templates by downloading them from [here](https://dl.bintray.com/cert-bdf/thehive/report-templates.zip)
1. Browse to TheHive via the Landing Page (http://CAPES_IP) or (http://CAPES_IP:9000)
1. Click "Update Database" and create an administrative account
1. Log in and in the top right, click your username and "Report Templates"
1. Click to "Import Templates" and upload the `report-templates.zip` file from above

## Get Started
After the CAPES installation, you should be able to browse to `http://capes_system` (or `http://capes_IP` if you don't have DNS set up) to get to the CAPES landing page and start setting up services.

I **strongly** recommend that you look at the `Build, Operate, Maintain` guides for these services before you get going. A few of the services launch a configuration pipeline that is hard to restart if you don't complete it the first time (I'm looking at you TheHive, Cortex, and Gitea).
