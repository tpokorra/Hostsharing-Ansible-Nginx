#!/bin/bash

max_certificates_per_run=5
certs_dir="$HOME/etc/certs"
USER=`id -nu`
PAC=$(echo $USER | awk '{split($0,a,"-"); print a[1]}')
PACHOSTNAME="$PAC.hostsharing.net"
listen80="$PACHOSTNAME:{{httpport}}"

if [ ! -d $HOME/etc/letsencrypt ]
then
  mkdir $HOME/etc/letsencrypt
fi

if [ ! -f $HOME/bin/acme_tiny.py ]
then
  wget https://raw.githubusercontent.com/diafygi/acme-tiny/master/acme_tiny.py -O $HOME/bin/acme_tiny.py
fi

if [ ! -f $HOME/etc/letsencrypt/account.key ]
then
  openssl genrsa 4096 > $HOME/etc/letsencrypt/account.key
fi

if [ ! -f $HOME/etc/letsencrypt/lets-encrypt-x3-cross-signed.pem ]
then
  wget https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem -O $HOME/etc/letsencrypt/lets-encrypt-x3-cross-signed.pem
fi

# create a new, unique Diffie-Hellman group, to fight the Logjam attack: https://weakdh.org/sysadmin.html
if [ ! -f $certs_dir/dhparams.pem ]
then
  mkdir -p $certs_dir
  openssl dhparam -out $certs_dir/dhparams.pem 2048
fi

if [ -z $1 ]
then
  echo "specify which domain should get a new lets encrypt certificate, or all"
  echo "$0 33-mydomain.com"
  echo "$0 all"
  exit -1
fi
domain=$1

function need_new_certificate {
domainconf=$1
domain=`basename $domainconf`
domain=${domain:0:-5}
need_new=0

crtfile=$certs_dir/$domain.crt

if [ ! -f $crtfile ]
then
  need_new=1
  return
fi

# TODO does the domain resolve to this host?

enddate=`openssl x509 -enddate -noout -in $crtfile | cut -d= -f2-`
# show date in readable format, eg. 2016-07-03
#date -d "$enddate" '+%F'
# convert to timestamp for comparison
enddate=`date -d "$enddate" '+%s'`
threeweeksfromnow=`date -d "+21 days" '+%s'`
echo "certificate valid till " `date +%Y-%m-%d -d @$enddate` $domain
if [ $enddate -lt $threeweeksfromnow ]
then
  need_new=1
fi
}

declare -A domain_counter
function new_letsencrypt_certificate {
domainconf=$1
domain=`basename $domainconf`
domain=${domain:0:-5}
posdash=`expr index "$domain" "-"`
domain=${domain:posdash}
challengedir=$HOME/var/tmp/$domain/challenge/.well-known/acme-challenge/

  # TODO this does not support toplevel domains like .co.uk, etc
  maindomain=`echo $domain | awk -F. '{print $(NF-1) "." $NF}'`
  maindomain=${maindomain/./_}
  counter=${domain_counter[$maindomain]}
  domain_counter[$maindomain]=$((${domain_counter[$maindomain]}+1))
  if [ ${domain_counter[$maindomain]} -gt $max_certificates_per_run ]
  then
    # To avoid hitting the limit of new certificates within a week per domain, we delay the certificate for the next run
    echo "delaying new certificate for $domain"
    return
  fi

  echo "new certificate for $domain"

  cd $HOME/etc/letsencrypt
  openssl genrsa 4096 > $domain.key
  openssl req -new -sha256 -key $domain.key -subj "/CN=$domain" > $domain.csr
  mkdir -p $HOME/etc/nginx.conf.d/disabled
  for f in $HOME/etc/nginx.conf.d/*.conf; do mv $f $HOME/etc/nginx.conf.d/disabled; done
  cat > $domainconf << FINISH
server {
    listen $listen80;
    server_name $domain;
    location /.well-known/acme-challenge/ { root $HOME/var/tmp/$domain/challenge; }
}
FINISH

  mkdir -p $challengedir
  cat $domainconf
  $HOME/bin/restart-nginx.sh
  sleep 3
  error=0
  python $HOME/bin/acme_tiny.py --account-key ./account.key --csr ./$domain.csr --acme-dir $challengedir > ./$domain.crt || error=1
  rm -Rf $HOME/var/tmp/$domain
  for f in $HOME/etc/nginx.conf.d/disabled/*; do mv $f $HOME/etc/nginx.conf.d; done

  if [ $error -eq 0 ]
  then
    cp -f $domain.key $certs_dir/$domain.key
    cat $domain.crt lets-encrypt-x3-cross-signed.pem > $certs_dir/$domain.crt
  else
    # disable this site to avoid that nginx cannot be started again
    mv $HOME/etc/nginx.conf.d/$domain.conf $HOME/etc/nginx.conf.d/disabled/
  fi

  $HOME/bin/restart-nginx.sh
  cd -

  if [ $error -eq 1 ]
  then
    exit -1
  fi
}

if [ "$domain" == "all" ]
then
  for f in $HOME/etc/nginx.conf.d/*
  do
    if [ -f $f ]
    then
      if [ "`cat $f | grep ssl`" != "" ]
      then
        need_new_certificate $f
        if [ $need_new -eq 1 ]
        then
          new_letsencrypt_certificate $f
        fi
      fi
    fi
  done
else
  new_letsencrypt_certificate $HOME/etc/nginx.conf.d/$domain.conf
fi

