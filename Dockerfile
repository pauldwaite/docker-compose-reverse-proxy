# syntax=docker/dockerfile:1.4

FROM nginx:1.25-alpine

ARG PROXIED_SERVICENAME
ENV PROXIED_SERVICENAME=$PROXIED_SERVICENAME
ARG PROXIED_HOSTNAME=localhost
ENV PROXIED_HOSTNAME=$PROXIED_HOSTNAME

RUN apk update && apk add openssl

# https://letsencrypt.org/docs/certificates-for-localhost/
RUN openssl req -x509 -out /etc/ssl/certs/proxied.crt -keyout /etc/ssl/private/proxied.key -newkey rsa:2048 -nodes -sha256 -subj '/CN='${PROXIED_HOSTNAME}'' -extensions EXT -config <(printf "[dn]\nCN=${PROXIED_HOSTNAME}\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:${PROXIED_HOSTNAME}\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
RUN chmod 644 /etc/ssl/certs/proxied.crt
RUN chmod 600 /etc/ssl/private/proxied.key

# https://docs.docker.com/engine/reference/builder/#example-creating-inline-files
COPY <<-ENDHEREDOC /etc/nginx/conf.d/reverse-proxy.conf
  gzip  on;
  server_tokens  off;

  server {
    listen 443 ssl;
    server_name ${PROXIED_HOSTNAME};
    ssl_certificate /etc/ssl/certs/proxied.crt;
    ssl_certificate_key /etc/ssl/private/proxied.key;

    location / {
      proxy_pass http://${PROXIED_SERVICENAME};
      }
    }
ENDHEREDOC

EXPOSE 443
