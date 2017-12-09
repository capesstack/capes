# Elastic's Kibana Build, Operate, Maintain
This project is created and maintained by the Elastic Beats team. All credit for the service goes to their talented team.

_Beats is the platform for single-purpose data shippers. They install as lightweight agents and send data from hundreds or thousands of machines to Logstash or Elasticsearch._

## Beats
Included with CAPES is Heartbeat and Metricbeat. While these two are very different, the BOM documentation is combined for simplicity.

For a description of Heartbeat and Metricbeat, please see the [README](README.md) at the root of this directory.

## Build
**It should be noted, this build is using Heartbeat and Metricbeat 5.6 to align with the installation of Elasticsearch and Kibana 5.6. When TheHive is updated to Elasticsearch 6.0, Kibana and Beats will be close behind.**

### Dependencies
There are no dependencies. Beats (Heartbeat and Metricbeat) are installed using `deploy_capes.sh` script in the root of this repository.

### Server Build
Please see the [server build instructions](../docs/README.md#build-your-os).

### Installation
Run the [CAPES deployment script](../deploy_capes.sh) or deploy manually:

Deploying with CAPES (recommended):
```
sudo yum install -y git
git clone https://github.com/capesstack/capes.git
cd capes
sudo sh deploy_capes.sh
```
Deploying manually:
```
sudo yum install -y https://artifacts.elastic.co/downloads/beats/heartbeat/heartbeat-5.6.5-x86_64.rpm https://artifacts.elastic.co/downloads/kibana/kibana-5.6.5-x86_64.rpm
sudo systemctl enable heartbeat.service
sudo systemctl enable metricbeat.service
sudo systemctl start heartbeat.service
sudo systemctl start metricbeat.service
```
**Note, version 6.0 changes the service name to `heartbeat-elastic.service` and `metricbeat-elastic.service`, so don't get twisted on which version you're working with when reading Elastic's documentation**

## Operate
One you have installed Beats, you need to go into Kibana and create the Heartbeat and Metricbeat Index Patterns.

Browse to http://<capes_ip> and select "Kibana" from the landing page. You will be directed to the Index setup page.

The Index Pattern for Heartbeat is `heartbeat-*` and the Index Pattern for Metricbeat is `metricbeat-*`.
![beats_setup](img/beats_setup.png)  

Once you have completed the Index Pattern setup, click on the "Discover Tab" on the top left of your screen to start exploring data.

## Maintain

### Package Locations
Heartbeat configuration file - `/etc/heartbeat/heartbeat.yml`  
Metricbeat configuration file - `/etc/metricbeat/metricbeat.yml`

### Update Configurations
Both Yaml files are available to update and are fairly straight forward to tweak and adjust; however, if you are looking to do something a bit more advanced, I recommend you check out the Elastic configuration guide for [Heartbeat](https://www.elastic.co/guide/en/beats/heartbeat/5.6/heartbeat-getting-started.html) and [Metricbeat](https://www.elastic.co/guide/en/beats/metricbeat/5.6/metricbeat-getting-started.html).
