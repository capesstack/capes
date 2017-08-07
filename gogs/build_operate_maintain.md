# GoGS Build, Operate, Maintain

## Build
After either running the [CAPES deployment script](../deploy_capes.sh) or the [independent GoGS deployment script](deploy_gogs.sh), you'll need to configure some environment variables to complete the installation and prepare for usage.

* When you browse to the setup page in the webUI, change the following:
  - The database user will not be `root`, it will be `gogs` and the password will be what you set at the beginning of the install process
  - The `Run User` will be `gogs` not `git`
  - Use the explicit IP of the GoGS server instead of `localhost` for the `Domain` and `Application URL` fields
  - Under `Server and other Services Settings` either use a legitimate Gravatar email address for the administrator account you will create or check the `Disable Avatar Service` box
  - Under `Admin Account Settings`, you're going to want to create an administrator (the account name cannot be `admin`)
