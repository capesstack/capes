# Etherpad Build, Operate, Maintain
This project is created and maintained by the Etherpad team. All credit for the service goes to their talented team.

_Etherpad allows you to edit documents collaboratively in real-time, much like a live multi-player editor that runs in your browser. Write articles, press releases, to-do lists, etc. together with your friends, fellow students or colleagues, all working on the same document at the same time._

_All instances provide access to all data through a well-documented API and supports import/export to many major data exchange formats. And if the built-in feature set isn't enough for you, there's tons of plugins that allow you to customize your instance to suit your needs._

## Build

### Dependencies
Below are the dependencies for Etherpad. These are installed using `deploy_capes.sh` script.

| Package      | Version           |
|--------------|-------------------|
| git          | 1.8.3.1-12.el7_4  |
| expect       | 5.45-14.el7_1     |
| openssl-devel| 1:1.0.2k-8.el7    |
| epel-release | 7-10              |
| mariadb-server | 1:5.5.56-2.el7 |
| nodejs       | 1:6.11.1-1.el7 |

### Server Build
Please see the [server build instructions](../docs/README.md#build-your-os).

### Installation
Run the [CAPES deployment script](../deploy_capes.sh) or or the [independent Etherpad deployment script](deploy_etherpad.sh).

Deploying with CAPES (recommended):
```
sudo yum install -y git
git clone https://github.com/capesstack/capes.git
cd capes
sudo sh deploy_capes.sh
```
Browse to `http://<CAPES-system>` and click the "Etherpad" from the "Services" dropdown.

Deploying manually:
```
sudo yum install -y git
git clone https://github.com/capesstack/capes.git
cd capes
sudo sh deploy_etherpad.sh
```
Browse to `http://<CAPES-system>:5000`

## Operate
Once you have completed the installation, you can start by creating simple pad's by visiting the page.

Additional functionality and extensibility of Etherpad is controlled with nodejs plugins.

### Administrative Functionality
Once you have installed Etherpad, you will want to browse to the administrative path and add some plugins for management.

#### ep_adminpads
A plugin for Etherpad allowing you to list, search, and delete pads.

It should be noted that you should be able to install `ep_adminpads` with `npm`, however, I cannot get it to show up after installation (`sudo npm install -g ep_adminpads`). If anyone knows how to do that and can do a PR, I can just build `ep_adminpads` into the install script.

To install ep_adminpads:
1. Browse to `http://<CAPES-system>:5000/admin`
1. Authenticate with `admin` and the credentials you created during the installation of Etherpad
1. Select `Plugin Manager`
1. Search for `adminpads`
1. Click `Install`
1. Wait for it to install, refresh your browser, and you will notice a `Manage pads` tab, or browse to `http://<CAPES-system>:5000/admin/pads`

## Maintain

### Package Locations
Etherpad location - `/opt/etherpad`   
Etherpad configuration location - `/opt/etherpad/settings.json`

## Troubleshooting
In the event that you have any issues, here are some things you can check to make sure they're operating as intended.

You may be having an issue with your firewall. Check the troubleshooting steps [here](../landing_page/build_operate_maintain.md#troubleshooting)

Check with the Etherpad project maintainers at http://etherpad.org/

If you're still unable to access the Etherpad page from a web browser, [please file an issue](https://github.com/capesstack/capes/issues).
