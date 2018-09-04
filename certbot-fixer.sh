#!/bin/bash

# A QAD script to upgrade from old versions of letsencrypt/certbot to certbot
# 0.23+ with directory-hooks

apt update
if [[ ! apt-cache show certbot | egrep -q "Version: 0.2[3456789]" ]]; then
apt install certbot

if [[ ! -d /etc/letsencrypt/renewal-hooks/post ]]; then
    echo "Certbot did not create hook directory; aborting"
    exit 1
fi

if [[ -x /usr/local/bin/certbot-auto ]]; then
    rm -rf /usr/local/bin/certbot-auto /usr/local/share/letsencrypt /opt/eff.org
    rm /etc/cron.*/letsencrypt
    if which nginx; then
        echo "/sbin/service nginx reload" > /etc/letsencrypt/renewal-hooks/post/nginx.sh
        chmod +x /etc/letsencrypt/renewal-hooks/post/nginx.sh
    elif which apache2ctl; then
        echo "/sbin/service apache2 reload" > /etc/letsencrypt/renewal-hooks/post/apache.sh
        chmod +x /etc/letsencrypt/renewal-hooks/post/apache.sh
    fi
fi

mv /etc/letsencrypt/renewal/*.sh /etc/letsencrypt/renewal-hooks/post/
