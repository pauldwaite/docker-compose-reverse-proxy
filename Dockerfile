# syntax=docker/dockerfile:1.4

FROM haproxy:2.8.7-alpine

ARG BACKEND_PORT
ENV BACKEND_PORT=$${BACKEND_PORT}
ARG BACKEND_REPLICAS
ENV BACKEND_REPLICAS=$${BACKEND_REPLICAS}
ARG BACKEND_SERVICE
ENV BACKEND_SERVICE=$${BACKEND_SERVICE}
ARG FRONTEND_HOSTNAME
ENV FRONTEND_HOSTNAME=$${FRONTEND_HOSTNAME}

USER root

RUN apk update && apk add openssl

# https://letsencrypt.org/docs/certificates-for-localhost/
# https://stackoverflow.com/questions/16480846/x-509-private-public-key
RUN openssl req \
  -x509 \
  -out    /etc/ssl/certs/reverseproxy.pem \
  -keyout /etc/ssl/certs/reverseproxy.pem \
  -newkey rsa:2048 \
  -nodes \
  -sha256 \
  -subj '/CN='$${FRONTEND_HOSTNAME}'' \
  -extensions EXT \
  -config <(printf "[dn]\nCN=$${FRONTEND_HOSTNAME}\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:$${FRONTEND_HOSTNAME}\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")

RUN chmod 644 /etc/ssl/certs/reverseproxy.pem

USER haproxy

# https://docs.docker.com/engine/reference/builder/#example-creating-inline-files
COPY <<END_OF_FILE /usr/local/etc/haproxy/haproxy.cfg

  defaults
    mode http

    timeout client 5000
    timeout connect 5000
    timeout server 5000

  frontend proxy
    bind $${FRONTEND_HOSTNAME}:80
    bind $${FRONTEND_HOSTNAME}:443 ssl crt /etc/ssl/certs/reverseproxy.pem
    # ? ssl crt
    #   - https://www.haproxy.com/blog/haproxy-ssl-termination

    default_backend proxied

    http-request redirect scheme https unless { ssl_fc }
    # ? http-request redirect
    #   - https://www.haproxy.com/blog/haproxy-ssl-termination#redirecting-from-http-to-https

  backend proxied
    balance roundrobin

    server-template $${BACKEND_SERVICE}- $${BACKEND_REPLICAS} $${BACKEND_SERVICE}:$${BACKEND_PORT} init-addr libc,none proto h2
    # ? server-template
    #   - https://stackoverflow.com/questions/68967624/how-to-access-docker-compose-created-replicas-in-haproxy-config

    # ? init-addr libc,none — hopefully prevents HAProxy getting stuck on one replica
    #   - https://stackoverflow.com/a/68977740/20578
    #   - http://docs.haproxy.org/2.8/configuration.html#5.2-init-addr

    # ? proto h2 — send unencrypted HTTP/2 to nginx
    #   - https://www.haproxy.com/documentation/haproxy-configuration-tutorials/load-balancing/http/#http%2F2-over-http-(h2c)-to-the-server

END_OF_FILE

EXPOSE 80 443