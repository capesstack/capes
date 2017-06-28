#!/bin/bash

# Admin note: on lines 13 & 42, you need to ensure that you change the password from "changeme" to something more secure.

# Install dependencies
sudo yum install gzip git curl python openssl-devel epel-release expect -y && sudo yum groupinstall "Development Tools" -y
sudo yum install nodejs mariadb-server -y

# Configure MySQL
sudo systemctl start mariadb.service
sudo systemctl enable mariadb.service
mysql -u root -e "CREATE DATABASE etherpad;"
mysql -u root -e "GRANT ALL PRIVILEGES ON etherpad.* TO 'etherpad'@'localhost' IDENTIFIED BY 'changeme';"
mysql -u root -e "FLUSH PRIVILEGES;"

# Need to automate this. This works as is, but requires interaction. Using the "expect" package should work
mysql_secure_installation

# Add the Etherpad user
sudo adduser etherpad

# Make firewall configurations
sudo firewall-cmd --add-port=9001/tcp --permanent
sudo firewall-cmd --reload

# Get the Etherpad packages
sudo mkdir -p /opt/etherpad
sudo git clone https://github.com/ether/etherpad-lite.git /opt/etherpad

# Configure the Etherpad settings
sudo cat > /opt/etherpad/settings.json <<EOF
{
  "title": "CAPES Etherpad",
  "favicon": "favicon.ico",
  "ip": "0.0.0.0",
  "port" : 9001,
  "showSettingsInAdminPage" : true,
   "dbType" : "mysql",
   "dbSettings" : {
                    "user"    : "etherpad",
                    "host"    : "localhost",
                    "password": "changeme",
                    "database": "etherpad",
                    "charset" : "utf8mb4"
                  },
  "defaultPadText" : "Welcome to the CAPES Etherpad.\n\nThis pad text is synchronized as you type, so that everyone viewing this page sees the same text. This allows you to collaborate seamlessly on documents.",
  "padOptions": {
    "noColors": false,
    "showControls": true,
    "showChat": true,
    "showLineNumbers": true,
    "useMonospaceFont": false,
    "userName": false,
    "userColor": false,
    "rtl": false,
    "alwaysShowChat": false,
    "chatAndUsers": false,
    "lang": "en-gb"
  },
  "padShortcutEnabled" : {
    "altF9"     : true, /* focus on the File Menu and/or editbar */
    "altC"      : true, /* focus on the Chat window */
    "cmdShift2" : true, /* shows a gritter popup showing a line author */
    "delete"    : true,
    "return"    : true,
    "esc"       : true, /* in mozilla versions 14-19 avoid reconnecting pad */
    "cmdS"      : true, /* save a revision */
    "tab"       : true, /* indent */
    "cmdZ"      : true, /* undo/redo */
    "cmdY"      : true, /* redo */
    "cmdI"      : true, /* italic */
    "cmdB"      : true, /* bold */
    "cmdU"      : true, /* underline */
    "cmd5"      : true, /* strike through */
    "cmdShiftL" : true, /* unordered list */
    "cmdShiftN" : true, /* ordered list */
    "cmdShift1" : true, /* ordered list */
    "cmdShiftC" : true, /* clear authorship */
    "cmdH"      : true, /* backspace */
    "ctrlHome"  : true, /* scroll to top of pad */
    "pageUp"    : true,
    "pageDown"  : true
  },
  "suppressErrorsInPadText" : false,
  "requireSession" : false,
  "editOnly" : false,
  "sessionNoPassword" : false,
  "minify" : true,
  "maxAge" : 21600, // 60 * 60 * 6 = 6 hours
  "abiword" : null,
  "soffice" : null,
  "tidyHtml" : null,
  "allowUnknownFileEnds" : true,
  "requireAuthentication" : false,
  "requireAuthorization" : false,
  "trustProxy" : true,
  "disableIPlogging" : false,
  "automaticReconnectionTimeout" : 0,
  "users": {
    "admin": {
      "password": "password",
      "is_admin": true
    },
  },
  "socketTransportProtocols" : ["xhr-polling", "jsonp-polling", "htmlfile"],
  "loadTest": false,
  "indentationOnNewLine": true,
  "toolbar": {
    "left": [
      ["bold", "italic", "underline", "strikethrough"],
      ["orderedlist", "unorderedlist", "indent", "outdent"],
      ["undo", "redo"],
      ["clearauthorship"]
    ],
    "right": [
      ["importexport", "timeslider", "savedrevision"],
      ["settings", "embed"],
      ["showusers"]
    ],
    "timeslider": [
      ["timeslider_export", "timeslider_returnToPad"]
    ]
  },
  "loglevel": "INFO",
  "logconfig" :
    { "appenders": [
        { "type": "console"
        //, "category": "access"// only logs pad access
        }
      ]
    }
}
EOF

# Give the Etherpad user ownership of the /opt/etherpad directory
sudo chown -R etherpad:etherpad /opt/etherpad

# Create the systemd Etherpad service
sudo cat > /usr/lib/systemd/system/etherpad.service <<EOF
[Unit]
Description=The Etherpad server
After=network.target remote-fs.target nss-lookup.target
[Service]
ExecStart=/opt/etherpad/bin/run.sh
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=etherpad
User=etherpad
[Install]
WantedBy=multi-user.target
EOF

# Configure the Etherpad service to start on boot and start it
# Your first boot will take a few minutes while the final npm dependencies are grabbed
sudo systemctl enable etherpad.service
sudo systemctl start etherpad.service

# Install success
cat << "EOF"
            :sssso.                      
           sy`:+--d-                     
           h+`hms`h+                     
           .o sM:.o                      
             .mMh`                       
             sMMM:                       
            `NNMNh                       
            sMdNdM/                      
           .moNMmsd                      
           oNs+N/hM/                     
          .doyhMysod`                    
          oy+yyNsy/m:                    
         `Nm: -N `oMd`                   
         os:syyNsyo-d/                   
        .m``/yhMhs: :d                   
        ohyy/`-N .+ysm/                  
       .dds:` -N  ./hdd`                 
       oo ./sysNoso:` d:                 
      `d.`-/ymMMMds/. /h`                
      omhNMms/:N./ymMmyN/                
     `Nms/.   -N    ./yNd                
      -+ys+-` -N  `:oss/`                
          -+sssNoss/.                    
             `./` 
EOF
echo "Your First boot will take a couple minutes while the final npm dependencies are grabbed."
echo "Browse to http://etherpad_server:9001 to get started, /admin for administrative functions."

# Note
# Highly recommend the adminpads plugin. You'll need to do it via the web UI at /admin/plugins and then restart Etherpad via `systemctl restart etherpad.service`.
# The adminpads plugin should be able to be installed via `npm install ep_adminpads`, but it isn't working. Have entered an issue with developer.
