# GoGS
The GoGS build script for CentOS 7.3.

## Usage
`$ sudo sh gogs_deploy.sh`

## Notes
* You'll need to enter your `sudo` credentials to install the dependencies.
* Remember the password you enter at the beginning of the script
* `mysql_secure_installation` runs after GoGS installation
* When you browse to the setup page in the webUI:
  - User will be `gogs` not `git`
  - Use the explicit localhost IP `127.0.0.1` instead of `localhost`
  - Either use a legitimate Gravatar email address for the adminisrator account you create or check the `Disable avatar lookup` box
