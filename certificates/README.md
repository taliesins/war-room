Download and install OpenSSL. 

Update `C:\data\certificates\localhost\ca.cnf` with the desired settings

Generate a CA certificate
```
openssl genrsa -des3 -out ca.key 4096
set OPENSSL_CONF=C:\data\certificates\localhost\ca.cnf
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt
```
Update `C:\data\certificates\localhost\dev.localhost.cnf` with the desired settings

```
set OPENSSL_CONF=C:\data\certificates\localhost\dev.localhost.cnf
openssl genrsa -des3 -out dev.localhost.key 4096
openssl req -new -key dev.localhost.key -out dev.localhost.csr 
openssl x509 -req -in dev.localhost.csr -out dev.localhost.crt -sha1 -CA ca.crt -CAkey ca.key -CAcreateserial -days 3650 -extensions req_ext -extfile dev.localhost.cnf
openssl rsa -in dev.localhost.key -out dev.localhost.key.nopassword
openssl pkcs12 -export -out dev.localhost.pfx -inkey dev.localhost.key -in dev.localhost.crt -certfile ca.crt
openssl pkcs12 -export -out dev.localhost.pfx.nopassword -inkey dev.localhost.key.nopassword -in dev.localhost.crt -certfile ca.crt
```

Add the CA certificate to your store
Add the certificate to your web server

_Please note that you can't generate wildcard certificates for top level domains i.e. *.localhost_