# CyberChef Build, Operate, Maintain
CyberChef was created, and is maintained, by the Government Communications Headquarters (GCHQ). GCHQ is one of the UK's security and intelligence agencies, working with its partners in MI5 and SIS. All credit for the service goes to their talented team.

_There are around 150 useful operations in CyberChef for anyone working on anything vaguely Internet-related, whether you just want to convert a timestamp to a different format, decompress gzipped data, create a SHA3 hash, or parse an X.509 certificate to find out who issued it._

_It’s the Cyber Swiss Army Knife._

There should probably be more here but...those GCHQ guys got their stuff together.

Of particular note, all images in the `.htm` file are base64 encoded, so there is no need for any Internet access for a good UX.

## Build

### Dependencies
Below are the dependencies for CyberChef. These are installed using `deploy_capes.sh` script.

| Package      | Version           |
|--------------|-------------------|
| epel-release | 7-10              |
| git          | 1.8.3.1-12.el7_4  |
| nginx        | 1:1.10.2-1.el7    |

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
Browse to `http://<CAPES-system>` and click the "CyberChef" from the "Services" dropdown.

Deploying manually:
```
sudo yum install epel-release -y && sudo yum update -y
sudo yum install nginx -y
sudo systemctl enable nginx
sudo curl https://gchq.github.io/CyberChef/cyberchef.htm -o /usr/share/nginx/html/cyberchef.htm
sudo firewall-cmd --add-port=80/tcp --permanent
sudo firewall-cmd --reload
sudo systemctl start nginx
```
Browse to `http://<CAPES-system>/cyberchef.htm`

## Operate
Drag the Operation to the Recipe, enter your input, and click "Bake!".

There are lots to experiment with.

## Maintain

### Package Locations
CyberChef location - `/usr/share/nginx/html/cyberchef.htm`   

### Update CyberChef
Easy, you can just download the newest `cyberchef.htm` file and put it in the proper directory:
```
sudo curl https://gchq.github.io/CyberChef/cyberchef.htm -o /usr/share/nginx/html/cyberchef.htm
```

## Troubleshooting
In the event that you have any issues, here are some things you can check to make sure they're operating as intended.

Check to make sure `cyberchef.htm` is in the proper directory:
```
ls /usr/share/nginx/html/cyberchef.htm
```
If you receive `ls: cannot access /usr/share/nginx/html/cyberchef.htm: No such file or directory`, re-collect it:
```
sudo curl https://gchq.github.io/CyberChef/cyberchef.htm -o /usr/share/nginx/html/cyberchef.htm
```
You may be having an issue with nginx or your firewall. Check the troubleshooting steps [here](../landing_page/build_operate_maintain.md#troubleshooting)

Check with the CyberChef project maintainers at https://github.com/gchq/CyberChef

If you're still unable to access the CAPES page from a web browser, [please file an issue](https://github.com/capesstack/capes/issues).
