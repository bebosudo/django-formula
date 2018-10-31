# Deployment of multiple django sites with SaltStack, using PostgreSQL, Gunicorn, NGINX and Let's Encrypt

The content of this directory provides a full-working example to deploy multiple Django websites, using SaltStack as the configuration management engine, exploiting different open-source tools, such as [Postgres](https://www.postgresql.org/) as database, Python virtualenvs to isolate applications, [gunicorn](https://gunicorn.org/) as the WSGI HTTP server communicating to [NGINX](https://nginx.org/) acting as a reverse proxy, and using [Let's Encrypt](https://letsencrypt.org/) to obtain HTTPS certificates.

A server with >1G RAM is suggested.

## Quickstart (tested on Centos 7)

Setup the Salt master, minion and api; download the [latest py3 version](https://repo.saltstack.com/#rhel) from the saltstack repo:
```console
# yum install -y nano epel-release https://repo.saltstack.com/py3/redhat/salt-py3-repo-2018.3-1.el7.noarch.rpm
# yum install -y salt-{master,minion,api} python34-pip git
# pip3.4 install GitPython
# echo '127.0.0.1 salt' >> /etc/hosts

# echo '127.0.0.1 salt' >> /etc/cloud/templates/hosts.redhat.tmpl   # on digitalocean's VMs
```

Download this repository to your server:
```console
# curl -L https://github.com/bebosudo/django-formula/archive/master.tar.gz > django-formula.tar.gz
# tar -xf django-formula.tar.gz
# cd django-formula-master
```

Put the deployment scripts in:
```console
# mv /etc/salt/master.d{,_orig}
# ln -s $PWD/example/master.d /etc/salt/master.d
# systemctl restart salt-master
# systemctl enable  salt-master
# systemctl restart salt-minion
# systemctl enable  salt-minion
# sleep 10s                      # Wait so communication between minions and master is set-up.

# salt-key --accept-all -y
# salt \* test.ping              # Verify that the minion (the node itself) is up and running.

# ln -s $PWD/example/salt   /srv/salt
# ln -s $PWD/example/pillar /srv/pillar
# salt \* saltutil.refresh_pillar
```

The pillar governing the sites configuration and installation is in `/srv/pillar/django_sites.sls`. By default it contains two example apps with sane defaults, so you should be able to test this formula straightaway.

To manually trigger the global setup, run:
```console
# rm -f /var/log/salt/{master,minion}; time \
      salt \* state.apply
```

After a while this should have setup two python websites at the IP of your server, at ports 8000 and 8001; you can get your public IP with: `curl icanhazip.com`.


## Pull from private git repositories

If the git repository you want to clone is private, or you want to download it using ssh, first create the user that will serve the application, then create a SSH key and add it to the git repo settings as a deploy key (details for [gitlab](https://docs.gitlab.com/ee/ssh/#deploy-keys), [github](https://developer.github.com/v3/guides/managing-deploy-keys/#deploy-keys) and [bitbucket](https://confluence.atlassian.com/bitbucket/use-deployment-keys-294486051.html)):

```console
# useradd shifu
# su - shifu
$ ssh-keygen -o -a 100 -t ed25519 -N "" -C "$(uname -n)" -f ~/.ssh/id_ed25519
$ ssh-keyscan gitlab.com >> ~/.ssh/known_hosts      # Add fingerprints to make interactions prompt-less.
                                                    # Change with github.com or bitbucket.org accordingly.
```


## HTTPS (TLS certificates) with Let's Encrypt

If you set a domain in the `url` field of one of the sites (and make it point to the public IP of your server), it will be used to request a HTTPS certificate from the Certificate Authority [Let's Encrypt](https://letsencrypt.org).

Several options are available to explicitly control the https requests and the nginx redirects to apply: see the commented `django_sites.sls` pillar.


### Staging vs Production certificates

By default, we request certificates to the [staging environment](https://letsencrypt.org/docs/staging-environment/) provided by Let's Encrypt, which results in certificates issued by the "Fake LE Intermediate X1" CA. \
This is done because the certificates requests to LE are rate-limited (to ensure fair usage to all the users): the staging environment has higher rate limits, so instead of 50 certificates per week you can request 30k; more details in the link above.

Once you are ready and confident of your setup and want to deploy your sites to production, you can switch to the production servers in the `letsencrypt.sls` pillar; make sure the final `config` variable is set like this:

```yaml
  config: |
    server = https://acme-v01.api.letsencrypt.org/directory
    # server = https://acme-staging.api.letsencrypt.org/directory
    ...
```


## Continuous Delivery with CherryPy and Github/Gitlab

SaltStack provides also a [event-driven](https://docs.saltstack.com/en/getstarted/event/) infrastructure we can leverage to automatically deploy the latest branch to production. \
Setup the CherryPy REST interface by linking the reactor directory from this repo with `ln -s $PWD/example/reactor /srv/reactor`.

Now open `/srv/reactor/git_hook.sls` and edit the secret key in the if: \
`{% if secret_key == 'change_super_secret_key_here!' %}` \
(on linux you can generate a random token with: `< /dev/urandom tr -dc 'A-Za-z0-9*,./:<=>?@[]^_{|}~' | head -c 100`).

Then (re)start the salt-api service and enable it at boot:

```console
# systemctl restart salt-api
# systemctl enable salt-api
```

Open a shell and execute: `salt-run state.event pretty=True` to watch live events as received by salt.


### Gitlab setup

If you are using gitlab, go to your project page, then `Settings` > `Integrations` (or fly to [gitlab.com/USERNAME/PROJECTNAME/settings/integrations](https://gitlab.com/USERNAME/PROJECTNAME/settings/integrations)); populate the form with the IP/domain of your project, and append `:8000/hook/push` (e.g., `http://example.com:8080/hook/push`), set the same secret token as before, leave the `Push events` trigger enabled, choose whether to enforce SSL verification and save. \
More details can be found [here](https://docs.gitlab.com/ee/user/project/integrations/webhooks.html#overview).

You can test a gitlab webhook directly from the web interface: it will send the last commit as if it was just pushed, and you can see the live event in the console opened before on your server.


### Github setup

Follow the instructions in the [official documentation](https://developer.github.com/webhooks/creating/).
Make sure you change the header token to `'X-Hub-Signature'`, as shown in the reactor config.


### Bitbucket

Despite what reported in their [documentation here](https://confluence.atlassian.com/bitbucketserver059/managing-webhooks-in-bitbucket-server-949255017.html), in the free version of bitbucket.com there's not a field for inputing a "Secret" as with other providers; feel free to ping me if you know how to setup bitbucket.
