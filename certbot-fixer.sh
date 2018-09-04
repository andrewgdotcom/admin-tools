#!/bin/bash

# A QAD script to upgrade from old versions of letsencrypt/certbot to certbot
# >=0.20 with directory-hooks

apt update
if [[ ! apt-cache show certbot | egrep -q "Version: 0.2[0123456789]" ]]; then
    echo "Can't find certbot >=0.23"
fi
apt install certbot

if [[ ! -d /etc/letsencrypt/renewal-hooks/post ]]; then
    echo "Certbot did not create hook directory; aborting"
    exit 1
fi

rm -rf /usr/local/bin/certbot-auto /usr/local/bin/letsencrypt /usr/local/share/letsencrypt /opt/eff.org
for i in /etc/cron.{daily,hourly,weekly,monthly}/letsencrypt; do
    mv $i $i.bak
done
if [[ -f /etc/cron.d/letsencrypt ]]; then
    mv /etc/cron.d/letsencrypt /root/letsencrypt.cron
fi

if which nginx; then
    echo "/sbin/service nginx reload 2>&1 | logger -t certbot" > /etc/letsencrypt/renewal-hooks/post/nginx.sh
    chmod +x /etc/letsencrypt/renewal-hooks/post/nginx.sh
elif which apache2ctl; then
    echo "/sbin/service apache2 reload 2>&1 | logger -t certbot" > /etc/letsencrypt/renewal-hooks/post/apache.sh
    chmod +x /etc/letsencrypt/renewal-hooks/post/apache.sh
fi

mv /etc/letsencrypt/renewal/post-hook.sh /etc/letsencrypt/renewal-hooks/post/

if [[ -f /etc/cron.d/certbot.dpkg-dist ]]; then
    mv /etc/cron.d/certbot{.dpkg-dist,}
fi

if [[ -x /usr/bin/letsencrypt && ! -L /usr/bin/letsencrypt ]]; then
    echo "WARNING: /usr/bin/letsencrypt exists and is not a soft link to certbot"
fi
