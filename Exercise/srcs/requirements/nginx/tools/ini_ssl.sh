#!/bin/bash
set -e



SSL_DIR=/etc/nginx/ssl
CERT="${SSL_DIR}"/nginx.crt
KEY="${SSL_DIR}"/nginx.key


echo "Initiating nginx"

mkdir -p "${SSL_DIR}"
domain_missing() { [ -z "${DOMAIN_NAME}" ]; }
if domain_missing; then
	echo "Error: DOMAIN_NAME environment variable not set"
	exit 1
fi

sed "s|\${DOMAIN_NAME}|${DOMAIN_NAME}|g" /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

cert_missing() { [ ! -f "${CERT}" ]; }
cert_expired() { ! openssl x509 -checkend 0 -noout -in "${CERT}" 2>/dev/null; }
cert_domain_mismatch() { ! openssl x509 -noout -checkhost "${DOMAIN_NAME}" -in "${CERT}" 2>/dev/null | grep -q "does match"; }
if cert_missing || cert_expired || cert_domain_mismatch(); then 
	echo "Creating SSL certificate for ${DOMAIN_NAME}"
	
	#-x509 output self signed X509 certificate instde of signing request
	#since its self signed it gives an warning since it cannot get the certification froma trusted source even though connection is secure
	#-nodes does not encrypt the private key so it can be stored at startup
	#-newkey rsa:2048 creates new 2048 bit RSA private key along with cert
	#-keyout specifies key outpath 
	#-out specifies cert outpath
	#-subj sets meta data, can set country etc not neeeded
	#	only needed is CN (common Name) tgat us chcked against hostname
	openssl req -x509 -nodes -days 30 -newkey rsa:2048 \
		-keyout "${KEY}" \
		-out "${CERT}" \
		-subj "/CN=${DOMAIN_NAME}" 2>/dev/null

	#read write owner
	chmod 600 "${KEY}"
	#read write owner group and others to readonly
	chmod 644 "${CERT}"

	echo "Certificate created at ${SSL_DIR}"
else
	echo "A valid certificate already exists"
fi

#tests nginx config
nginx -t
echo "Starting Nginx"
exec nginx
