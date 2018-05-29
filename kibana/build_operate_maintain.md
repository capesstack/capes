# Elastic's Kibana Build, Operate, Maintain
This project is created and maintained by the Elastic Kibana team. All credit for the service goes to their talented team.

_Kibana lets you visualize your Elasticsearch and Beats data and navigate the Elastic Stack, so you can do anything from learning why you're getting paged at 2:00 a.m. to understanding the impact rain might have on your quarterly numbers._

We use Kibana to visualize data from the CAPES stack regarding the service and system health; although it can be used to visualize any Elasticsearch data, such as the data from [ROCKNSM](http://rocknsm.io).

## Build
### Dependencies
There are no dependencies. Kibana is installed using `deploy_capes.sh` script in the root of this repository.

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
sudo yum install -y https://artifacts.elastic.co/downloads/kibana/kibana-5.6.5-x86_64.rpm firewall-cmd
sudo sed -i "s/#server\.host: \"localhost\"/server\.host: \"0\.0\.0\.0\"/" /etc/kibana/kibana.yml
sudo firewall-cmd --add-port=5601/tcp --permanent
sudo firewall-cmd --reload
sudo systemctl enable kibana.service
sudo systemctl start kibana.service
```

## Operate
Browse to http://<capes_ip> and select "Kibana" from the landing page. You will be directed to the Index setup page or the Discover Tab if you have previously set up Index Patterns. If you installed without the entirely of CAPES, browse to http://<kibana_ip>:5601.

The Index Pattern for Heartbeat is `heartbeat-*` and the Index Pattern for Metricbeat is `metricbeat-*`
![beats_setup](img/beats_setup.png)

## Maintain

### Package Locations
Kibana configuration file - `/etc/heartbeat/heartbeat.yml`  

### Update Configurations
Kibana's Yaml file is mostly untouched with the exception of allowing remote access to the Kibana interface by changing the default `#server.host: "localhost"` to `server.host: "0.0.0.0"` to allow any IP to access Kibana. Of note, this is addressed in the above Installation steps.

If you want to connect Kibana to other Elasticsearch nodes, you can do so in this configuration file.

Additional documentation is available on [Elastic's Kibana page](https://www.elastic.co/guide/en/kibana/current/getting-started.html).
