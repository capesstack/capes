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
1. Either create a new account with `write` permissions or use an existing account, create and reveal the API key, copy this down
1. Collect the [TheHive configuration manager](https://github.com/TheHive-Project/TheHive-Resources/tree/master/contrib/ManageConfig)
1. Collect the [capes-config.conf](capes-config.conf) file
```
$ git clone https://github.com/TheHive-Project/TheHive-Resources.git
$ cd TheHive-Resources/contrib/ManageConfig
$ python3 submit_config.py -k <API key> -u http://thehive-url:9000 -c capes-config.conf
```
1. You'll want to refresh your browser and all of the Case Templates and Custom Fields should be in there and ready for use.Â
