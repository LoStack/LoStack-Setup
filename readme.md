# LoStack Setup

This readme covers the high-level setup of LoStack

Currently only Ubuntu / Ubuntu Server and Rasbian have setup dedicated setup guides and scripts, however the instructions should be easy to follow on other systems like Fedora with some basic knowledge of your system.

The main requirements are:
 - A host Linux OS with a static IP with support for Docker and the Docker Compose plugin
 - Basic DNS access, you need to be able to (best to worst):
    - Create a DNS record on your router to point LoStack's hostname to its IP address (easiest, but not all routers support it)
    - ***OR***
    - Add LoStack as a secondary DNS to your router
    - ***OR***
    - Add LoStack as a secondary DNS to the device connecting to LoStack
    - ***OR***
    - Add a local record on your computer / device accessing it


## Setup Guide
This guide will walk you through the steps of setting up a fresh instance of LoStack on a new OS.
LoStack is currently in alpha, and things may break - it is not recommended for production or enterprise systems.


 1. Install an OS
    - Currently only Ubuntu / Ubuntu Server and Raspbian are officially supported hosts for the setup guide, however you can still follow along if you can install Docker and Docker Compose for your specific OS manually.
    - If you are using Ubuntu / Ubuntu Server *DO NOT* install Docker / Compose during the OS install - it will install the wrong version of Docker (usually through Snap) and Docker Compose will not work properly.
    - If/when promted during setup, configure the device with a static IP address native to your local subnet (e.g. 192.168.1.X, 10.1.1.X, etc.).
    
 2. Clone Repo and Install Docker:
    - Make Docker dir, modify permissions, and move to it
        - `sudo mkdir -p /docker && sudo chmod -R 750 /docker && cd /docker`
    - Clone this repo into it
        - `git clone https://github.com/LoStack/LoStack-Setup ./`
    - Run the Docker install script for your system, this installs Docker and the Docker Compose plugin. If you already have Docker and Compose installed you can skip this step.
        - `sudo bash ./setup.sh`
            - This script will automatically select the right Debian version of the Docker Compose plugin, running `./scripts/setup-ubuntu.sh` or `./scripts/setup-arm.sh`

 4. Configure Docker / LoStack
    - Copy template.env to .env
        - `cp ./template.env ./.env`
    - Edit the .env file, the template contains detailed explanations for the various options. 
        - `nano ./.env`
            - If you do not have the ability to add a custom DNS record to your router, make sure you set `FIRST_RUN_CREATE_COREDNS_CONFIG=true` to generate the needed CoreDNS config file for later.

 5. First Launch
    - LoStack's Docker containers must be launch in a specific order the very first time it runs in order to properly create all needed config files.
        1. **OpenLDAP, MariaDB** -> These will be populated by LoStack First Run on the next step
        2. **LoStack First Run** -> Creates needed config files, and configures OpenLDAP and MariaDB 
        3. **Lostack Traefik Authelia** -> Start the login and reverse proxy system
        - A script is included to handle the first launch proceedure.
        - *MAKE SURE YOU HAVE CONFIGURED YOUR ENV FILE BEFORE RUNNING THIS SCRIPT OR YOU WILL HAVE TO REMOVE CONTAINERS AND CONFIG FILES AND RE-RUN IT IS CERTAIN VARIABLES HAVE NOT BEEN CONFIGURED*
        - `sudo bash first_run.sh`
            - This will create all needed config files, populate OpenLDAP and MariaDB, and launch all services for the first time in the correct order.
        - Some containers (such as Authelia) will generate misconfigured default configuration files if launched without running the LoStack first launch process correctly.

 6. DNS
    
    At this point you will need to do one of the following:
    
    - Create a DNS record for lostack.internal and *.lostack.internal
        - Not all routers support this, but this is usually the easiest method if yours does.
        - This method will make the services accessible to everyone on the network.

    **OR**

    This section covers replacing the default resolver with CoreDNS, you need to do this if you want to add CoreDNS as a secondary resolver to either your router, or an individual device accessing services on the host.

    - Replace the DNS on the host with CoreDNS
        - This involves removing the built-in resolver on Linux, and replacing it with a Docker container.
            - When you remove the resolver, your system won't be able to resolve hostnames to IPs. You **MUST** download the CoreDNS container before removing the resolver or you will be unable to fetch the image.
            - CoreDNS can be launched once before removing the resolver to cache it locally. It will FAIL TO LAUNCH, this is expected due to the container trying to bind to port 53 which is currently in use by the resolver.
            - To cache CoreDNS run `sudo docker compose up -d coredns` and wait for it to complain about being unable to bind port 53
            - Remove the resolver
                ```
                sudo systemctl disable systemd-resolved
                sudo systemctl stop systemd-resolved
                ```
            - Run `sudo docker compose up -d coredns` again, this time it should start successfully. You should now have a working resolver again. Try `curl https://github.com` to see if it is working.

    
    - Next, add the IP of your host to the router or access device as a secondary DNS:
        - Most routers support adding a secondary DNS
        - This method will make the services accessible to everyone on the network.
        - If you add it as a secondary DNS directly on a device accessing the services, by other devices on the network won't resolve it. This method is useful if you are working with LoStack in a VM.

    **OR**
    
    - Add a local record on your computer / device
        - This process varies based on the OS you are connecting with
        - This is not the recommended way to connect to LoStack, has not been well tested, and will likely require manual configuration per-subdomain.
    
 7. Connecting + trusting self-signed certs
    - Assuming everything has gone correctly, you should now be able to access the site by going to https://lostack.lostack.dev/
    - You will get a warning about the site's certificate not being trusted, this is expected as the certificate is not signed by a known authority. 
    - To fix this, and prevent issues with websockets in some services, you should tell your system to trust the certificate.
    - This varies by system, however you can normally click the lock icon to the left of the URL on your browser, click Certificate -> Details -> Export, then double-click the cert to install it. There may also be an additional step required to trust the certificate.

 8. At this point you should be good to go! Have fun playing with services, and please report any bugs! 
