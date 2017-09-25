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
I would **strongly** recommend that you browse to TheHive web application and configure your username and passphrase before you do anything else. If you skip this, or browse there with `curl` or `wget`, you'll have to reset the admin creds directly in Elasticsearch...and it's a less than smooth process. I recommend setting up your `username:passphrase` first.

### Cortex Project
Browse to `http://$HOSTNAME:9001` (or `http://$IP:9001` if you don't have DNS set up) to begin using the service.

#### Cortex Configuration
You'll still need to enter your specific API / service credentials for the individual analyzers located in `/etc/cortex/application.conf` and then restart Cortex with `sudo systemctl restart cortex.service`.

## Moving to Elasticsearch 5.2 (roadmap)
The JVM doesn't seem to play nice with this yet. It doesn't install to the `Update Database` configuration.
```
# Dependencies
sudo yum install java-1.8.0-openjdk.x86_64 epel-release firewalld -y && sudo yum update -y
sudo yum groupinstall "Development Tools" -y
sudo yum install https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.2.2.rpm libffi-devel python-devel python-pip ssdeep-devel ssdeep-libs perl-Image-ExifTool file-devel -y

# Configure Elasticsearch
sudo bash -c 'cat > /etc/elasticsearch/elasticsearch.yml <<EOF
network.host: 127.0.0.1
script.inline: on
cluster.name: hive
#threadpool.index.queue_size: 100000
#threadpool.search.queue_size: 100000
#threadpool.bulk.queue_size: 1000
EOF'
```
