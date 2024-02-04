Example compose.yaml file:

```
services:

  actual_website:
    build: .

  reverseproxy:
    build:
      context: ../local-https-reverse-proxy
      args:
        PROXIED_SERVICENAME: actual_website
        PROXIED_HOSTNAME: actual_website.localhost

    depends_on:
      - actual_website

    ports:
      - '443:443'
```

Then pop this at the end of your /etc/hosts file:

```
127.0.0.1	actual_website.localhost
```