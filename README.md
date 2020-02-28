# Intro to DevOps Workshop
A workshop demonstrating some DevOps concepts by building an automated 
deployment blog server.

# Using This Workshop
Use the [Terraform](https://www.terraform.io/downloads.html) files provided to 
create a GitHub repo based off of the workshop template. This will create a repo
with terraform for students to be able to clone and add their DNS records to. 
**You must do this in a GitHub Organization. Individual repos aren't supported 
by GitHub yet.** Set the terraform variables in `terraform.tfvars`

* `workshop_title` - Title of the workshop. Will be part of the GitHub repo.
Don't put the word *workshop* in the title.
* `github_organization` - Organization for the repo to be created in.
* `github_token` - Your GitHub API Token. Can set it in this file or export
it as `TF_VAR_github_token`


# Workshop Sections
There are 4 sections, broken up into chunks to allow for break and review
points. Currently the parts below are just the commands to be done with little
explanation. Written explanation will come later as the workshop is given a 
few times.

**This is mostly for me, this would be a *terrible* self guide to learn from. 
The code works, but the explanation is all in my head**

## Part 1 - Initial Server Setup
1. Deploy an Ubuntu 18.04 server on [DigitalOcean](https://www.digitalocean.com/)
2. SSH in as root and create personal user
    ```
    adduser dumbledore
    usermod -aG sudo dumbledore
    ```
3. Create `.ssh` folder and add keys to login with
    ```
    mkdir /home/dumbledore/.ssh
    cp ~/.ssh/authorized_keys /home/dumbledore/.ssh/
    chown -R dumbledore:dumbledore /home/dumbledore/.ssh/
    ```
4. Log out and try to login as your user. Make sure you can and can use 
`sudo -i` to become root.
5. Setup ssh to disallow root login
    ```
    ...
    vim /etc/ssh/sshd_config
    ...
    PermitRootLogin yes -> PermitRootLogin no
    ```
6. Restart `sshd` so the changes take effect
    ```
    systemctl restart sshd
    ```
7. Get the package lists for the repositories and updates. Most cloud providers
purge these lists in their images to make them smaller and to ensure you get the
latest packages.
    ```
    apt update
    ```
8. Install a web server, nginx
    ```
    apt install nginx
    ```
9. Start the webserver
    ```
    systemctl start nginx
    ```
10. View the default page at your IP Address
11. Create a custom HTML page at `/var/www/html/index.html`
12. Ensure your Unix permissions are set to 644 or `-rw-r--r--`
12. View your new page at your IP Address

## Part 2 - DNS

1. Go over the essentials of DNS
2. All participants should fork repo created before workshop
(see [Using This Workshop](#using-this-workshop)) and add a resource for a DNS
record pointing to their server.
    ```
    resource "digitalocean_record" "YOUR_NAME" {
        domain = data.digitalocean_domain.web.name
        type   = "A"
        name   = "my-dns-record"
        value  = "PUT_YOUR_IP_HERE"
        ttl    = 30
    }
    ```
3. Submit a PR. Once all are submitted execute the terraform to setup DNS
records.

## Part 3 - Creating a Blog with Hugo
1. Hugo is a static site generator. These types of tools are used to create 
a theme that is easily applied to any type of article. You typically write
your content in markdown then the tool generates a website for you.
2. Use wget to install the latest `hugo` binary
    ```
    wget https://github.com/gohugoio/hugo/releases/download/v0.65.3/hugo_0.65.3_Linux-64bit.tar.gz
    ```
3. Extract the tarball
    ```
    tar -xvf TARFILE
    ```
4. Use sudo to move the file to `/usr/local/bin`
    ```
    sudo mv hugo /usr/local/bin/
    ```
5. Go to [themes.gohugo.io](https://themes.gohugo.io/) and find a theme that
you like. Click on the theme and you'll be taken to the GitHub page of the
theme. Leave this page open
*One I know works and looks good is [book](https://themes.gohugo.io/hugo-book/)*

6. Back in your terminal create a new hugo site
    ```
    hugo new site mysite
    ```
7. Change directories into the site
    ```
    cd mysite
    ```
8. Initialize this directory as a git repo
    ```
    git init
    ```
9. Create a git submodule of the theme you want. This allows you to have a local
copy of the theme that is linked to the upstream so if you choose to update it
you can.
    ```
    git submodule add https://github.com/alex-shpak/hugo-book themes/book
    ```
10. Copy an example of the site out of the theme into the main directory.
    ```
    cp -R themes/MY_THEME/exampleSite/content .
    ```
11. Open your `config.toml` and specify what theme you're using, change
the title of your site to something more fun, and change the baseURL to your
fully qualified domain name. **Don't forget the trailing `/` !**
    ```
    baseURL = "http://workshop.egger.codes/"
    languageCode = "en-us"
    title = "Intro to DevOps Workshop"
    theme = "book"
    ```

12. Explore the theme. All Hugo themes are created differently. Make some
changes to the site so you can tell it's not just the theme.
13. Let's deploy the site now. Run the `hugo` command to build the static assets
for the website.
    ```
    hugo
    ```
14. Clear out the `/var/www/html` directory and move your static assets to the
website directory.
    ```
    sudo rm -rf /var/www/html/*
    sudo mv public/* /var/www/html/
    ```
15. Visit your website using your DNS name and your website should be there.
16. Let's use a tool called `certbot` (a client for Let's Encrypt) to get a 
free HTTPS certificate.
    ```
    sudo apt install certbot python-certbot-nginx
    ```
17. Now let's run the command and setup HTTPS for our site. Answer the questions
when prompted. Put your FQDN when asked for your domain name. Also, it is a 
good idea to make everything redirect to HTTPS.
    ```
    sudo certbot --nginx
    ```
18. Finally, our certificates expire. Let's setup a cron job to renew our
certificate
    ```
    sudo apt install chrony
    sudo crontab -e 

    ...
    30 2 * * 1 /usr/bin/certbot renew
    ...

    sudo systemctl start chrony
    ```

## Part 4 - CI/CD
1. Create a git repo and push your code to it.
2. Go to [Travis-CI](https://travis-ci.com), login by linking your GitHub
Account.
3. Add the following files to your repo. Explain

`Dockerfile`

    FROM fedora

    RUN dnf install -y wget

    RUN wget -O hugo.tar https://github.com/gohugoio/hugo/releases/download/v0.65.3/hugo_0.65.3_Linux-64bit.tar.gz

    RUN tar -xvf hugo.tar

    RUN mv hugo /usr/local/bin/

    WORKDIR /data
    

`.travis.yml`
```
language: generic
services:
    - 'docker'
before_script: 'make build-docker'
script: 'make package'
branches:
    only:
    - master
before_deploy:
    # Set up git user name and tag this commit
    - git config --local user.name "YOUR_NAME"
    - git config --local user.email "YOUR_EMAIL"
    - export TRAVIS_TAG=${TRAVIS_TAG:-$(date +'%Y%m%d%H%M%S')-$(git log --format=%h -1)}
    - git tag $TRAVIS_TAG
deploy:
    provider: releases
    api_key: $GITHUB_TOKEN
    file: website.tar.gz
    skip_cleanup: true
```

`Makefile`
```
clean:
	rm -rf website.tar
build-docker:
	docker build -t website .
package:
	docker run -v `pwd`:/data -it website /data/scripts/build-website.sh
```

`scripts/build-website.sh`
```
#!/bin/bash

hugo -s my_site
mkdir website && mv my_site/public/* website
tar -zcvf website.tar.gz website
rm -rf website
```

4. Create a GitHub token and add to Travis so it can deploy.
5. Now, everytime you commit to master your website will be built and
automatically uploaded to GitHub as a release.
6. Now let's use [webhooks](https://developer.github.com/webhooks/) to automate
this deployment process. Download a webhook server and install it
```
wget https://github.com/adnanh/webhook/releases/download/2.6.11/webhook-linux-amd64.tar.gz
tar -xvf webhook-linux-amd64.tar.gz
sudo mv webhook-linux-amd64/webhook /usr/local/bin/
```
7. Create a redeploy script for our webhook to execute. Put it in `/var/scripts/redeploy.sh`. Don't forget to
`chmod 755`. Also be sure to install `jq`
```
#!/bin/bash
TAG=`curl --silent "https://api.github.com/repos/YOUR_GITHUB_USER/YOUR_REPO/releases/latest" | jq -r .tag_name`
wget https://github.com/YOUR_GITHUB_USER/YOUR_REPO/releases/download/$TAG/website.tar.gz
tar -xvf website.tar.gz &> /dev/null
rm -rf /var/www/html/*
cp -R website/* /var/www/html/
rm -rf website.tar.gz website
```

8. Create a systemd script to run the webhook service in `/etc/systemd/system/webhook.service`
```
[Unit]
Description=Webhook for Github

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/webhook -nopanic -cert /etc/letsencrypt/live/YOUR_FQDN/fullchain.pem -key /etc/letsencrypt/live/YOUR_FQDN/privkey.pem -hooks /var/webhook/hooks.yaml -secure -verbose
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=webook

[Install]
WantedBy=multi-user.target
```

9. Create a webhook JSON with the appropriate secret in `/var/webhook/hooks.yaml`
Beware tabs. Yaml hates that
```
---
- id: redeploy-webhook
  execute-command: "/var/scripts/redeploy.sh"
  command-working-directory: "/var/webhooks"
  trigger-rule:
    match:
      type: payload-hash-sha1
      secret: p424K4gU5eRdDxdCDGgtKwTZjXxBQh78UKnUkK4tzTxWuM8KBMYqnykvycaYXjJR
      parameter:
        source: header
        name: X-Hub-Signature
```
10. Now everytime you commit your code should auto build and deploy
11. crontab for restarting webhooks