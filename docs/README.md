# Documentation
Please see below for specifics on the different web apps
* [CAPES Landing Page](landing_page)  
* [CyberChef](CyberChef)  
* [Etherpad](etherpad)  
* [GoGS](gogs)  
* [MISP](misp)  
* [Mumble](mumble)  
* [Rocketchat](rocketchat)  
* [TheHive](TheHive)  
* [Cortex](cortex)  

## Requirements
There has not been extensive testing, but all of these services have run without issue on a single virtual machine with approximately 20 users and no issue for a week. That said, your mileage may vary.

While the OS version isn't a hard requirement, all testing and development work has been done with `CentOS 7.3.1611 (Core)`.

| Component | Number |
| - | - |
| Cores | 4 |
| RAM | 8 GB |
| Hard Disk | 20 GB |

## Secure Deployment
There is an inherent risk to deploying web applications to the Internet or to a contested networking enclave -- basically, somewhere the bad guys can get to.

To address this, the CAPES project has done a few things to help protect these web applications and left a few things for you, the operator, to close in on as your need requires.

### Secure by Design
#### Operating System
While there are a lot of projects that are developed using Ubuntu (many of these service creators still follow that path), CAPES chose to use CentOS because of a few different reasons:  
1. CentOS is the open source version of Red Hat Enterprise Linux (RHEL)
    - Many enterprises use RHEL as their Linux distribution of choice because you can purchase support for it
    - We wanted to use a distribution that could easily be ported from an open source OS to the supported OS (RHEL)
1. CentOS uses Security Enhanced Linux (SELinux) instead of AppArmor
    - SELinux uses context to define security controls (for example, I know a text editor shouldn't talk to the Internet because it's a text editor, not a browser)
    - AppArmor uses prescripted rules to define security controls (for example, I know that a text editor shouldn't talk to the Internet because someone told me it shouldn't)

#### Implementation
While the `iptables` is running on CAPES and the only ports listening have services attached to them, you should still consider using a Web Application Firewall, an Intrusion Detection System (IDS) or a Network Security Monitor (like [ROCKNSM](rocknsm.io) - which has an IDS integrated on top of a litany of other goodies) to ensure that your CAPES stack isn't being targeted.

If possible, CAPES, just like a passive NSM, should *not* be on the contested network. This will prevent it from being targeted by aggressors. On net responses (re: enhanced web application security) are a roadmap item.

#### Securing the Landing Page
We are going to implement a login for the CAPES landing page. Right now, CAPES should not be deployed where an aggressor can get at it...however, that's not really an excuse. We're working on it. **All services have authentication requirements.**

Additionally, SSL. We are having discussions around self-signed certificates vs. 3rd party (Let's Encrypt, etc.); but there are some architecture caveats to consider here. Again, it's a roadmap item.

## Installation
Generally, the CAPES ecosystem is meant to run as a whole, so the preferred usage will be to install CAPES with the `deploy_capes.sh` script in the root directory of this repository. Additionally, if there is a service that you do not want, you can comment that service out of the deploy script as they are documented with service headers.

That said, there is a deploy script for each of the services that you should be able to run individually if your use case requires that.

### Build your OS
This is meant to help those who need a step-by-step build of CentOS, securing SSH, and getting ready to grab CAPES. If you don't need this guide, skip on down to [Get CAPES](#get-capes).
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
    - Select `STIG for CentOS Linux 7 Server`
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
1. We're not going to set a Root password because CAPES will never, ever need it. Ever. Not setting a password locks the Root account.
1. Create a user, but ensure that you toggle the `Make this user administrator` checkbox
1. Once the installation is done, click the `Reboot` button in the bottom right to...well...reboot
1. Login using the account you created during the Anaconda setup
    - Run the following commands
      ```
      sudo yum update -y && sudo yum install git firewall-cmd -y` (Enter the password you created in Anaconda)
      sudo firwall-cmd --add-port=22/tcp --permanent
      sudo firewall-cmd --reload
      sudo sed '$s/^/\#/' /etc/ssh/sshd_config
      sudo systemctl restart sshd.service
      ```
1. Secure ssh
  - On your management system, create an SSH keypair
    ```
    ssh-keygen -t rsa` accept the defaults, but enter a passphrase for your keys
    ssh-copy-id your_created_user@<ip of CAPES>
    ssh your_created_user@<ip of CAPES>
    sudo sed -i 's/\#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo systemctl restart sshd.service
    ```
## Get CAPES
Finally, here we go.
```
git clone https://github.com/peasead/capes.git
# if you're feeling adventurous git clone -b devel https://github.com/peasead/capes.git
cd capes
sudo sh deploy_capes.sh
```
This will start the automated build of:
* Configure NTP (likely already done, but in the event you skipped the [Build your OS](#build-your-os) above)
* Configure a hostname (again, likely already done, but just to be sure)
* Install Rocketchat
* Install GoGS
* Install Etherpad
* Install TheHive
* Install Cortex
* Install Nginx
* Install the CAPES landing page
* Secure the MySQL installation
* Make firewall changes
* Set everything to autostart
