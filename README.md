Example compose.yaml file:

```
services:

  actual_website:
    build: .

    deploy:
      mode: replicated
      replicas: 2

  reverseproxy:
    depends_on:
      - actual_website

    environment:
      BACKEND_PORT: 80
      BACKEND_REPLICAS: 2
      BACKEND_SERVICE: actual_website
      CERTIFICATE_FILENAME: actual_website_localhost.pem
      FRONTEND_HOSTNAME: actual_website.localhost

    hostname: actual_website.localhost

    image: pauldwaite/docker-compose-reverse-proxy

    ports:
      - '80:80'
      - '443:443'

    volumes:
      - ./local_https_certificate:/usr/local/etc/haproxy/certs
```

To create the local HTTPS certificate:

```
% docker run \
  --env FILENAME=actual_website_localhost.pem \
  --env HOSTNAME=actual_website.localhost \
  --volume .:/usr/local/share \
  pauldwaite/local-https-certificate
```

To trust the HTTPS certificate on macOS:

1. Open Keychain Access
2. Drag the certificate file onto Keychain Access, and add it to your login keychain
3. Select the login keychain in the left-hand menu of Keychain Access, and click on Certificates
4. Double-click on the certificate you just added (actual_website.localhost, or whatever hostname you specified when creating it)
5. Expand the “Trust” bit, and change the “When using this certificate” dropdown to “Always trust”
6. Restart your web browser

To access the site from your browser, pop this at the end of your /etc/hosts file:

```
127.0.0.1 actual_website.localhost
```

Then visit https://actual_website.localhost/
