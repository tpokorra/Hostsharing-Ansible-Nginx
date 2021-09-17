#!/bin/bash

if [ -z $1 ]; then
  echo "call: $0 domain"
  echo "   which will publish files in doms/domain/htdocs"
  exit
fi

DOMAIN=$1
USER=`id -nu`
PAC=$(echo $USER | awk '{split($0,a,"-"); print a[1]}')
PACHOSTNAME="$PAC.hostsharing.net"
NGINXLOGPATH=$HOME/var/log
CERTSPATH=$HOME/etc/certs

wildcardurl="wildcard".$( echo $DOMAIN | cut -d '.' -f 2- )
if [ -f $CERTSPATH/$wildcardurl.crt ]; then
  generateCert=0
  CERTNAME=$wildcardurl
elif [ -f $CERTSPATH/$DOMAIN.crt ]; then
  generateCert=0
  CERTNAME=$DOMAIN
else
  generateCert=1
  CERTNAME=$DOMAIN
fi

if [ -f ~/etc/nginx.conf.d/$DOMAIN.conf ]; then
  echo "there is already a configuration for $DOMAIN"
  exit
fi

mkdir -p ~/etc/nginx.conf.d
cat ~/etc/nginx.sslconf.tpl | \
    sed "s#PACHOSTNAME#$PACHOSTNAME#g" | \
    sed "s#NGINXPORT80#{{httpport}}#g" | \
    sed "s#NGINXPORT443#{{httpsport}}#g" | \
    sed "s#DOMAIN#$DOMAIN#g" | \
    sed "s#NGINXLOGPATH#$NGINXLOGPATH#g" | \
    sed "s#CERTSPATH#$CERTSPATH#g" | \
    sed "s#CERTNAME#$CERTNAME#g" \
    > ~/etc/nginx.conf.d/$DOMAIN.conf

if [ $generateCert -eq 1 ]
then
  ~/bin/letsencrypt.sh $DOMAIN
fi
