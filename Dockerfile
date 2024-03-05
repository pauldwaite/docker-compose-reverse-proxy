# syntax=docker/dockerfile:1.4

FROM haproxy:2.8.7-alpine

# https://docs.docker.com/engine/reference/builder/#example-creating-inline-files
COPY <<"END_HAPROXY_CONFIG" /usr/local/etc/haproxy/haproxy.cfg

  defaults
    mode http

    timeout client 5000
    timeout connect 5000
    timeout server 5000

  frontend proxy
    bind "${FRONTEND_HOSTNAME}":80
    bind "${FRONTEND_HOSTNAME}":443 ssl crt /usr/local/etc/haproxy/certs/"${CERTIFICATE_FILENAME}"
    # ? ssl crt
    #   - https://www.haproxy.com/blog/haproxy-ssl-termination

    default_backend proxied

    http-request redirect scheme https unless { ssl_fc }
    # ? http-request redirect
    #   - https://www.haproxy.com/blog/haproxy-ssl-termination#redirecting-from-http-to-https

  resolvers docker
    nameserver dns1 127.0.0.11:53
  # ? resolvers docker — hopefully helps prevent HAProxy getting stuck on one replica?
  #   - https://stackoverflow.com/a/68977740/20578

  backend proxied
    balance roundrobin

    server-template "${BACKEND_SERVICE}"- "${BACKEND_REPLICAS}" "${BACKEND_SERVICE}":"${BACKEND_PORT}" resolvers docker init-addr libc,none proto h2
    # ? server-template
    #   - https://stackoverflow.com/questions/68967624/how-to-access-docker-compose-created-replicas-in-haproxy-config

    # ? resolvers docker — hopefully prevents HAProxy getting stuck on one replica?
        - https://stackoverflow.com/a/68977740/20578

    # ? init-addr libc,none — hopefully prevents HAProxy getting stuck on one replica (although maybe not?)
    #   - https://stackoverflow.com/a/68977740/20578
    #   - http://docs.haproxy.org/2.8/configuration.html#5.2-init-addr

    # ? proto h2 — send unencrypted HTTP/2 to nginx
    #   - https://www.haproxy.com/documentation/haproxy-configuration-tutorials/load-balancing/http/#http%2F2-over-http-(h2c)-to-the-server

END_HAPROXY_CONFIG

EXPOSE 80 443
