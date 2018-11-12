# TheHive Build, Operate, Maintain

## Build
After either running the [CAPES deployment script](../deploy_capes.sh) or the [independent TheHive deployment script](deploy_thehive.sh), you'll need to configure some environment variables to complete the installation and prepare for usage.

## Case Templates
If you're interested in pre-built case templates, we've added a few:

* Account Enumeration
* Attack Public-Facing Application
* Drive-by Compromise
* Malware Infection
* Network Enumeration
* Phishing
* Unknown Account
* Unknown Scheduled Task
* Unknown Service

Along with the case templates, we've also included 9 custom fields. Some of these custom fields connect to the [RockNSM](http://rocknsm.io) project, so they may not all be applicable.

If you want to upload the case templates, they are included in the TheHive [templates directory](templates). They can be uploaded 1 at a time from the Case Templates menu.

### Caveat
The case templates **do not** include the custom fields. If you want the custom fields and all the templates at once, you'll need to upload the entire CAPES configuration (recommended).

## Upload Configuration
To get the custom fields with the templates, you'll need to upload the whole configuration file (which is recommended). After this configuration file is uploaded you can make any additional changes that you'd like. The below steps should be performed on your system, not CAPES:

1. Ensure you have [Python3](https://www.python.org/) installed
1. Log into TheHive as an administrator
1. Click on the `Admin` dropdown and select `Users`
1. Either create a new account with `admin` permissions or use an existing account, create and reveal the API key, copy this down
1. Collect the [TheHive configuration manager](https://github.com/TheHive-Project/TheHive-Resources/tree/master/contrib/ManageConfig)
1. Collect the [capes-config.conf](capes-config.conf) file
```
$ git clone https://github.com/TheHive-Project/TheHive-Resources.git
$ cd TheHive-Resources/contrib/ManageConfig
$ python3 submit_config.py -k <API key> -u http://thehive-url:9000 -c capes-config.conf
```
1. You'll want to refresh your browser and all of the Case Templates and Custom Fields should be in there and ready for use.

## Troubleshooting
You should use the `capes_processes status` command to identify if any CAPES services aren't running as expected.

### Failed Service
If TheHive has failed, check your local host file to ensure that there is a static entry for CAPES or it is resolvable via DNS. Example:
```
cat /etc/hosts
192.168.100.100 capes_hostname
```
If the CAPES management IP and hostnames aren't present or correct (and they should be from the build script), update that using the above format and restart the service
```
sudo systemctl restart thehive.service
```
Give it a couple of seconds and then rerun `capes_processes status` or `sudo systemctl status thehive.service`.  
![DNS Haiku](http://i.imgur.com/eAwdKEC.png)

### Web Application Available, No Database
If you can get to the web interface, but are getting errors that the database isn't online, check to ensure that Elasticsearch is running. If you ran the `capes_processes status` command, you'll know.

You can try to restart Elasticsearch with `sudo systemctl restart elasticsearch.service` and monitor it with `capes_processes status`.
