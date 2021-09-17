server {
    listen PACHOSTNAME:NGINXPORT80;
    server_name DOMAIN;
    return 302 https://$host$request_uri;
}

server {
    listen PACHOSTNAME:NGINXPORT443 ssl;
    server_name DOMAIN;

    ssl_certificate CERTSPATH/CERTNAME.crt;
    ssl_certificate_key CERTSPATH/CERTNAME.key;
    ssl_session_cache shared:SSL:10m;
    ssl_protocols  TLSv1 TLSv1.1 TLSv1.2;  # don't use SSLv3 ref: POODLE

    # Logjam https://weakdh.org/sysadmin.html
    ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';
    ssl_prefer_server_ciphers on;
    ssl_dhparam CERTSPATH/dhparams.pem;

    access_log  NGINXLOGPATH/DOMAIN.access.log;
    error_log   NGINXLOGPATH/DOMAIN.error.log;

    root /home/pacs/{{pac}}/users/{{user}}/doms/DOMAIN/htdocs;

    index index.html;
    location / {
       ssi on;
    }
}
