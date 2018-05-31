# Cyber Analytics Platform and Examination System (CAPES)
![capes logo](http://capesstack.io/capes_logo.png)

**People ask from time-to-time what help is needed - documentation. If you see documentation that is wrong, be it grammar, incorrect guidance, or missing; please consider doing a PR correcting it. I will gladly give contributor status to anyone who does anything to make this project easier for people to get started.**

CAPES is an operational-focused service hub for segmented, self-hosted, and offline (if necessary) incident response, intelligence analysis, and hunt operations.

![capes architecture](http://capesstack.io/capes_arch.png)

## Services in CAPES
1. Mattermost (Chat)
1. HackMD (Collaboration-style documentation)
1. Gitea (Version controlled documentation)
1. TheHive (Incident Response)
1. Cortex (Indicator enrichment)
1. CyberChef (Data analysis)
1. Mumble (VoIP)
1. Beats - Metric, Heart, and File (Performance and health metrics)
1. Kibana (Data visualization)

## Roadmap
1. Get working shell script for all services
1. Get shell scripts combined into a singular CAPES deploy script
1. Documentation *
1. Convert CAPES to Docker

## Note
\* designates current effort

## Documentation / Installation
See [docs](docs/README.md) for detailed instructions.  

### CentOS 7.4
```
$ sudo yum -y install git
$ git clone https://github.com/capesstack/capes.git
$ cd capes
$ sudo sh deploy_capes.sh
```
### Pre-CentOS 7.4
```
$ sudo yum install -y https://kojipkgs.fedoraproject.org/packages/http-parser/2.7.1/3.el7/x86_64/http-parser-2.7.1-3.el7.x86_64.rpm
$ sudo yum -y install git
$ git clone https://github.com/capesstack/capes.git
$ cd capes
$ sudo sh deploy_capes.sh
```

## Get Started
After the CAPES installation, you should be able to browse to `http://your_capes_system` (or `http://your_capes_IP` if you don't have DNS set up) get get to the CAPES landing page and start setting up services by following the [post installation steps](https://github.com/capesstack/capes/tree/master/docs#post-installation).

Although most of these services are fairly intuitive, I **strongly** recommend that you look at the [Build, Operate, Maintain](https://github.com/capesstack/capes/tree/master/docs#documentation) guides for these services before you get going too far. A few of the services launch a configuration pipeline that is obnoxious to restart if you don't complete it the first time (I'm looking at you TheHive and Gitea).

# Troubleshooting
Please see the [documentation](https://github.com/capesstack/capes/tree/master/docs#documentation) or feel free to open a [GitHub Issue](https://github.com/capesstack/capes/issues).

Want to join the discussion? Send a request to join our Slack Workspace to contact [at] capesstack[.]io

# Swag
Interested in some CAPES swag? Send me a email to contact [at] capesstack[.]io and I'll send you some laptop decals.

If you're interested in CAPES t-shirts, we parter with TeeSpring for those. Feel free to check out [our storefront](https://teespring.com/stores/capesstack). We don't make a penny on these - 100% of the profits go to the National Alliance to End Homelessness.

# Training & Professional Services
While CAPES is a FOSS project and we'll attempt to support deployment questions via the Issues page, if you need training or PS, please feel free to check out some options over at [Perched](http://perched.io)
