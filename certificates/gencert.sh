#!/usr/bin/env bash

gen_ca_cert() {
	certPassword="changeme"
	export OPENSSL_CONF=ca.cnf

	openssl genrsa -des3 -passout pass:$certPassword -out ca.key 4096

	openssl req -new -x509 -days 3650  -key ca.key -passin pass:$certPassword -out ca.crt
}

gen_server_cert() {
	export OPENSSL_CONF=dev.localhost.cnf

	openssl genrsa -des3 -passout pass:$certPassword -out dev.localhost.key 4096 
	openssl req -new -key dev.localhost.key -passin pass:$certPassword  -out dev.localhost.csr
	openssl x509 -passin pass:$certPassword -req -in dev.localhost.csr -out dev.localhost.crt -sha1 -CA ca.crt -CAkey ca.key -CAcreateserial -days 3650 -extensions req_ext -extfile dev.localhost.cnf
	openssl rsa -passin pass:$certPassword -in dev.localhost.key -out dev.localhost.key.nopassword
	openssl pkcs12 -export -passout pass:$certPassword -out dev.localhost.pfx -inkey dev.localhost.key -passin pass:$certPassword -in dev.localhost.crt -certfile ca.crt
	openssl pkcs12 -export -passout pass:$certPassword -out dev.localhost.pfx.nopassword -inkey dev.localhost.key.nopassword -passin pass:$certPassword -in dev.localhost.crt -certfile ca.crt
}

gen_certs() {
	if [ ! -f ca.crt ]; then
    	echo "Certificate authority not found. Generating ca.crt ..."
		gen_ca_cert
	else
		echo "Found Certificate authority ca.crt"
    
	fi

	if [ ! -f dev.localhost.pfx ]; then
    	echo "Server cert not found. Generating"
		gen_server_cert
	else
		echo "Found Server Certificate"
    
	fi

}
