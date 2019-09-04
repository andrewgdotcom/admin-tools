Apache
======

My recommended Apache SSL configuration:

(Note that while CAMELLIAGCM is defined in the TLS1.2 standard, it is not implemented in openssl)

mods-available/ssl.conf:

```
## Apache <2.4.36 || OpenSSL <1.1.1
SSLProtocol TLSv1.2
## Apache >=2.4.36 && OpenSSL >=1.1.1
# SSLProtocol TLSv1.3 +TLSv1.2
SSLHonorCipherOrder on
SSLCipherSuite \
  "EECDH+AESGCM EECDH+AESCCM EECDH+CHACHA20 EECDH+ARIA \
  EDH+AESGCM EDH+AESCCM EDH+CHACHA20 EDH+ARIA \
  @STRENGTH"
SSLCompression off

## Strict Transport Security
<IfModule mod_headers.c>
	Header set Strict-Transport-Security "max-age=15768000"
</IfModule>

## Apache 2.4 only
SSLUseStapling on
SSLStaplingResponderTimeout 5
SSLStaplingReturnResponderErrors off
SSLStaplingCache shmcb:/var/run/ocsp(128000)

## Apache >=2.4.8 && OpenSSL >=1.0.2
SSLOpenSSLConfCmd DHParameters /etc/ssl/certs/dhparam.pem
```

	NB YOU MUST NOT USE TABS TO INDENT THE CONTINUATION LINES!
	modssl will choke on embedded tabs in the ciphersuite list

conf.d/security:

```
<IfModule mod_headers.c>
	Header unset X-Powered-By
	Header set X-Frame-Options: "sameorigin"
	Header set X-Content-Type-Options: "nosniff"
</IfModule>
TraceEnable Off
ServerTokens Prod
ServerSignature Off
```

Incant:

```
a2enmod mod_headers
openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
apache2ctl graceful
```

Nginx
======

/etc/nginx/snippets/ssl-params.conf:

```
# from https://cipherli.st/
# and https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html

ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
ssl_prefer_server_ciphers on;
ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
ssl_ecdh_curve secp384r1;
ssl_session_cache shared:SSL:10m;
ssl_session_tickets off;
ssl_stapling on;
ssl_stapling_verify on;
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 5s;
# Disable preloading HSTS for now.  You can use the commented out header line that includes
# the "preload" directive if you understand the implications.
#add_header Strict-Transport-Security "max-age=63072000; includeSubdomains; preload";
add_header Strict-Transport-Security "max-age=63072000; includeSubdomains";
add_header X-Frame-Options DENY;
add_header X-Content-Type-Options nosniff;

ssl_dhparam /etc/ssl/certs/dhparam.pem;
```

Incant:

	openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

/etc/nginx/snippets/ssl-<website>.conf:

```
ssl_certificate /etc/letsencrypt/live/<website>/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/<website>/privkey.pem;
```

And in /etc/nginx/sites-available/<website>.conf:

```
    include snippets/ssl-<website>.conf;
    include snippets/ssl-params.conf;
```

Tomcat
======

My recommended Tomcat/Jboss configuration:

```
<Connector sslEnabled="true"
sslDisableCompression="true"
sslProtocol="TLS"
ciphers="TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,
TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA,
TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,
TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA,
TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256,
TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA,
TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384,
TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA,
TLS_RSA_WITH_AES_128_CBC_SHA256,
TLS_RSA_WITH_AES_128_CBC_SHA,
TLS_RSA_WITH_AES_256_CBC_SHA256,
TLS_RSA_WITH_AES_256_CBC_SHA"
...
```

To support IE7/8 on XP, append the following cipher:

```
TLS_RSA_WITH_3DES_EDE_CBC_SHA
```

JBoss
-----

If you get an inexplicable "no certificate file" error, try changing the protocol:

```
protocol="org.apache.coyote.http11.Http11Protocol"
```

Source: https://developer.jboss.org/thread/171293


DNS
===

Add the following to the @ record of your zone:

```
        IN CAA 128	issue "letsencrypt.org"
        IN CAA 128	issuewild "letsencrypt.org"
        IN CAA 128	iodef "mailto:root@example.com"
```

https://blog.qualys.com/ssllabs/2017/03/13/caa-mandated-by-cabrowser-forum

References
==========

https://wiki.mozilla.org/Security/Server_Side_TLS
