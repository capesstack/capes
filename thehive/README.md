# TheHive
TheHive build script for CentOS 7.3.

## Usage
`$ sudo sh thehive_deploy.sh`

### Notes
You'll need to enter your `sudo` credentials to install the dependencies.

## Post Installation
### TheHive Project
Browse to `http://$HOSTNAME:9000` (or `http://$IP:9000` if you don't have DNS set up) to begin using the service.

#### Note
I would recommend that you browse to TheHive web application and configure your username and password. If you skip this, or browse there with `curl` or `wget`, you'll have to reset the admin creds directly in Elasticsearch...and it's a less than smooth process. I recommend setting up your `username:password` first.

#### TheHive <-> Cortex Configuration
Prior to connecting TheHive to Cortex, you'll need to update `/etc/thehive/application.conf` with your Cortex server:
```
# Cortex
play.modules.enabled += connectors.cortex.CortexConnector
cortex {
  "CORTEX-SERVER-ID" {
  url = "http://$HOSTNAME:9001"
  }
}
```

Then reload TheHive service `sudo systemctl restart thehive.service`

#### TheHive <-> Cortex Report Templates
1. Log in TheHive using an administrator account
1. Go to `Admin` > `Report templates` menu
1. Click on `Import templates` button and select the `report-templates.zip` file located in `/opt/cortex/`

### Cortex Project
Browse to `http://$HOSTNAME:9001` (or `http://$IP:9001` if you don't have DNS set up) to begin using the service.

#### Cortex Configuration
You'll still need to enter your specific API / service credentials for the individual analyzers located in `/etc/cortex/application.conf` and then restart Cortex with `sudo systemctl restart cortex.service`.
