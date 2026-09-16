#!/bin/bash
set -e

SSL_DIR=/etc/nginx/ssl
CERT=/etc/nginx/ssl/nginx.crt

mkdir -p "${SSL_DIR}"

domain_missing() { [ -z "${DOMAIN_NAME}" ]; }
if domain_missing; then
	echo "Error: DOMAIN_NAME environment variable not set"
	exit 1
fi

cert_missing() { [ ! -f "${CERT}" ] }
cert_expired() { ! openssl x509 -checkend 0 -noout -in "${CERT}" 2 >/dev/null; }
if cert_missing || cert_expired; then 
	echo "Creating SSL certificate for ${DOMAIN_NAME}"
	
	#-x509 output self signed X509 certificate instde of signing request
	#-nodes does not encrypt the private key so it can be stored at startup
	#-newkey rsa:2048 creates new 2048 bit RSA private key along with cert
	openssl req -x509 -nodes -days 30 -newkey rsa:2048 \
		-key