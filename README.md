# Cyber Analytics Platform and Examination System (CAPES)
![capes logo](http://capesstack.io/capes_logo.png)

**People ask from time-to-time what help is needed - documentation. If you see documentation that is wrong, be it grammar, incorrect guidance, or missing; please consider doing a PR correcting it. I will gladly give contributor status to anyone who does anything to make this project easier for people to get started.**

This is the project page for the CAPES project (in order of priority).

CAPES is an operational-focused service hub for segmented, self-hosted, and offline (if necessary) incident response, intelligence analysis, and hunt operations.

![capes architecture](http://capesstack.io/capes_arch.png)

## Services
1. Rocketchat
1. Etherpad
1. Gitea
1. TheHive
1. Cortex
1. Landing Page
1. CyberChef
1. Mumble
1. Kibana (with Heartbeat and Metricbeat)
1. Hippocampe *

## Roadmap
1. Get working shell script for all services
1. Get shell scripts combined into a singular CAPES deploy script
1. Documentation *
1. Convert shell script to Ansible
1. Convert CAPES to Docker

## Done
* Working shell scripts
  - RocketChat
  - Etherpad
  - Gitea
  - Mumble
  - TheHive
  - Cortex
  - Kibana (with Heartbeat and Metricbeat)
  - CyberChef
  - CAPES Landing Page
* CAPES deploy script with Landing Page presenting:
  - RocketChat
  - CyberChef
  - Gitea
  - Mumble
  - Etherpad
  - TheHive
  - Cortex
  - Kibana (with Heartbeat and Metricbeat)

## Note
\* designates current effort

## Documentation / Installation
See [docs](docs/README.md) for detailed instructions.  
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
## Usage
1. See the [Build, Operate, Maintain guides](docs/README.md) to complete post-installation configuration
1. Browse to http://capes_IP
