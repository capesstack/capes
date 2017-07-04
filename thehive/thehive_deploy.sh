sudo yum install java-1.8.0-openjdk.x86_64 -y
sudo yum install https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/rpm/elasticsearch/2.4.2/elasticsearch-2.4.2.rpm

sudo bash -c 'cat > /etc/elasticsearch/elasticsearch.yml <<EOF
network.host: 127.0.0.1
script.inline: on
cluster.name: hive
threadpool.index.queue_size: 100000
threadpool.search.queue_size: 100000
threadpool.bulk.queue_size: 1000
EOF'

sudo yum install https://dl.bintray.com/cert-bdf/rpm/thehive-project-release-1.0.0-3.noarch.rpm -y
sudo yum install thehive -y

(cat << _EOF_
play.crypto.secret="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)"
_EOF_
) | sudo tee -a /etc/thehive/application.conf

sudo firewall-cmd --add-port=9000/tcp --permanent
sudo firewall-cmd --reload

sudo chown -R thehive:thehive /opt/thehive
sudo chown thehive:thehive /etc/thehive/application.conf
sudo chmod 640 /etc/thehive/application.conf

sudo systemctl enable elasticsearch.service
sudo systemctl enable thehive.service
sudo systemctl start elasticsearch.service
sudo systemctl start thehive.service
