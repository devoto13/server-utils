# server-utils

This is utility to configure Ubuntu server for easy configuration and deployment of simple application inside Docker containers.

## Prerequisite

Ubuntu with Docker installed.

## Install

- Create file system structure:

```
$ sudo mkdir -p /web/infrastructure /web/apps /web/utils
$ sudo chown devoto13:devoto13 /web/infrastructure /web/apps /web/utils
```

- Install and configure Supervisor:

```
$ sudo apt-get install supervisor
$ sudo chown devoto13:root /etc/supervisor/conf.d
$ cat /etc/supervisor/supervisord.conf

[unix_http_server]
file=/var/run/supervisor.sock                                  
chmod=0770                                                        
chown=devoto13:root

[supervisord]
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid 
childlogdir=/var/log/supervisor

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///var/run/supervisor.sock

[include]
files = /etc/supervisor/conf.d/*.conf 
```

- Install Nginx:

```
$ mkdir /web/infrastructure/nginx
$ cd /web/infrastructure/nginx
$ cat fig.yml

nginx:
  image: devoto13/nginx
  ports:
    - 80:80
  net: host
  volumes:
    - sites:/etc/nginx/sites-available
    - log:/var/log/nginx

$ cat /etc/supervisor/conf.d/nginx.conf

[program:nginx]
command=fig up
directory=/web/infrastructure/nginx
stopsignal=INT
```

- Clone repository:

```
$ cd /web/utils && git clone https://github.com/devoto13/server-utils.git .
```
