Example compose.yaml file:

```
services:

  actual_website:
    build: .

    deploy:
      mode: replicated
      replicas: 2

  reverseproxy:
    build:
      args:
        BACKEND_PORT: 80
        BACKEND_REPLICAS: 2
        BACKEND_SERVICE: site
        FRONTEND_HOSTNAME: actual_website.localhost

      context: .

    depends_on:
      - actual_website

    hostname: actual_website.localhost

    ports:
      - '80:80'
      - '443:443'
```

Then pop this at the end of your /etc/hosts file:

```
127.0.0.1	actual_website.localhost
```

To trust the HTTPS certificate on macOS:

1. `% docker compose cp reverseproxy:/etc/ssl/certs/reverseproxy.pem ~/Desktop/reverseproxy.pem`
2. Open Keychain Access
3. Drag the file onto Keychain Access, and add it to your login keychain
4. Select the login keychain in the left-hand menu of Keychain Access, and click on Certificates
5. Double-click on the certificate you just added (actual_website.localhost, or whatever hostname you specified)
6. Expand the “Trust” bit, and for “When using this certificate”, change the dropdown to “Always trust”
7. Restart your web browser, and visit https://actual_website.localhost/