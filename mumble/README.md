# Mumble

# Update murmur.ini
sudo sed -i 's/database=/database=\/var\/lib\/murmur\/murmur\.sqlite/' /etc/murmur.ini
sudo sed -i 's/\#logfile=murmur\.log/logfile=\/var\/log\/murmur\/murmur\.log/' /etc/murmur.ini
sudo sed -i 's/\#pidfile=/pidfile=\/var\/log\/murmur\/murmur\.pid/' /etc/murmur.ini

# Update Firewall
sudo firewall-cmd --permanent --add-port=64738/tcp
sudo firewall-cmd --reload
