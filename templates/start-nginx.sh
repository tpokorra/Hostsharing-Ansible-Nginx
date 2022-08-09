#!/bin/bash

# just to be sure we don't have a running nginx
killall -u {{pac}}-{{user}} nginx

/usr/sbin/nginx -c $HOME/etc/nginx.conf -p $HOME/var

