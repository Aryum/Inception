#!/bin/bash
set -e

SSL_DIR=/etc/nginx/ssl
CERT="${SSL_DIR}"/nginx.crt
KEY="${SSL_DIR}"/nginx.key

echo "Initiating nginx"

envsubst '${NGINX_PORT} ${WP_PORT} ${DOMAIN_NAME}' \
	< /etc/template/nginx.conf.template \
	> /etc/nginx/nginx.conf

mkdir -p "${SSL_DIR}"
domain_missing() { [ -z "${DOMAIN_NAME}" ]; }
if domain_missing; then
	echo "Error: DOMAIN_NAME environment variable not set"
	exit 1
fi

cert_missing() { [ ! -f "${CERT}" ]; }
cert_expired() { ! openssl x509 -checkend 0 -noout -in "${CERT}" 2>/dev/null; }
cert_domain_mismatch() { ! openssl x509 -noout -checkhost "${DOMAIN_NAME}" -in "${CERT}" 2>/dev/null | grep -q "does match"; }
if cert_missing || cert_expired || cert_domain_mismatch; then 
	echo "Creating SSL certificate for ${DOMAIN_NAME}"
	openssl req -x509 -nodes -days 30 -newkey rsa:2048 \
		-keyout "${KEY}" \
		-out "${CERT}" \
		-subj "/CN=${DOMAIN_NAME}" 2>/dev/null

	chmod 600 "${KEY}"
	chmod 644 "${CERT}"

	echo "Certificate created at ${SSL_DIR}"
else
	echo "A valid certificate already exists"
fi

nginx -t
echo "Starting Nginx"
exec nginx
