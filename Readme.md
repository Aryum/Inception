# MariaDB Setup

| File | Purpose |
|------|---------|
| `50-server.cnf` | Server configuration (read by `mysqld` on every start) |
| `init_db.sh` | Entrypoint script: initializes the data directory, creates the database and users, then starts MariaDB |


## `init_db.sh` step by step

`set -e` 
makes the script stop as soon as a command fails

`database_missing()` 
checks if the data directory was initialized, setting the user to `mysql`

`mysqld --skip-networking --skip-grant-tables --socket="${SOCKET}" --user=mysql & pid="$!"`
we start a temporary server without networking, skipping permission checking so we can update password without issues
saving the process id to be used later

`mysqladmin --socket="${SOCKET}" ping --silent --wait=30 --connect-timeout=3`
tries connection with the server, if its unsucessful it exits with an error

`mysql --socket=${SOCKET} -u root` with here doc
setups/updates database passwords

`timeout 30 env MYSQL_PWD="${MYSQL_ROOT_PASSWORD}" mysqladmin --socket="${SOCKET}" -u root shutdown`
sends a shutdown signal, as root user passing password through env variable so it doesnt appear on the command line

`wait "$pid" || true`
waits for the server to shutdown, || true stops set -e from stoping script if the server returns an error

`exec mysqld --user=mysql --datadir="${DB_DIR}" --socket="${SOCKET}"`
starts the real server, making mariadb the contianer's main process (PID1)


## `50-server.cnf` options

Sets for folders for log and data folder, files for pid, log socket (file used for process communication). Also sets bind adress to 0.0.0.0 so it listens on all IPv4 network interfaces and the user that the server will run as.


# Nginx Setup
| File | Purpose |
|------|---------|
| `nginx.conf` | Nginx configuration. It is used as a **template** (`/etc/nginx/nginx.conf.template`) because it contains the placeholder `${DOMAIN_NAME}` |
| `ini_ssl.sh` | Entrypoint script: fills in the domain, creates a self-signed SSL certificate if needed, tests the config, and starts nginx |

---

## Required environment variable

| Variable | Meaning |
|----------|---------|
| `DOMAIN_NAME` | Domain the site is served on. It is inserted into the config and used as the certificate's Common Name |

---

## `ini_ssl.sh` step by step

`set -e` 
makes the script stop as soon as a command fails. The certificate and key paths are stored in variables, and 

`mkdir -p` 
creates `/etc/nginx/ssl` if it doesn't exist.

`domain_missing()`
checks if DOMAIN_NAME env var is set and not empty

`sed "s|\${DOMAIN_NAME}|${DOMAIN_NAME}|g" /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf`
the nginx config file does not read env variables so we create a new config file with the real domain name


`cert_missing()`, `cert_expired()`, `cert_domain_mismatch()`
checks if certificate is missing, it has expired or it has changed, and thus creating a new one only if needed

`openssl req -x509 -nodes -days 30 -newkey rsa:2048 -keyout "${KEY}" -out "${CERT}" -subj "/CN=${DOMAIN_NAME}"`

creates a self signed certificate, since it is not signed by a tursted certificate authority, browser cannot verify who is behind it. The connection **is encrypted** but the server's identity **is not verified**, which means it does not protect against someone impersonating the server. This is why the browser shows a warning.

| Option | Meaning |
|--------|---------|
| `req -x509` | Output a **self-signed certificate** directly, instead of a certificate signing request |
| `-nodes` | "No DES": the private key is **not encrypted with a passphrase**, so nginx can read it at startup without anyone typing a password. Newer OpenSSL calls this `-noenc` |
| `-days 30` | The certificate is valid for 30 days |
| `-newkey rsa:2048` | Generate a new 2048-bit RSA private key together with the certificate |
| `-keyout` / `-out` | Where to save the private key / the certificate |
| `-subj "/CN=..."` | Sets the certificate's subject (country, organization, etc. could also be set). Only the Common Name (CN) is given here, set to the domain |


`chmod 600 "${KEY}"`
Sets key permissions to read/write for the owner only
`chmod 644 "${CERT}"`
Sets certificate permissions read/write for the owner, read-only for group and others

The private key must stay secret. The certificate is public information, so it can be readable by anyone

`nginx -t`
checks the config syntax and that the certificate and key files can be loaded

`exec nginx` 
replaces the shell with nginx, so nginx becomes the container's main process (PID 1).



## `nginx.conf` explained
 
### Global settings
| Directive | Explanation |
|-----------|-------------|
| `user www-data;` | User the worker processes run as. |
| `daemon off;` | Keeps nginx in the foreground. |
 
### `events` block
`worker_connections 1024;` is the maximum number of simultaneous connections each worker process can hold.
 
### `http` block
Holds all the HTTP/HTTPS settings. `include /etc/nginx/mime.types;` maps file extensions to content types (for example `.css` becomes `text/css`), so browsers handle each file correctly.
 
### `server` block
| Directive | Explanation |
|-----------|-------------|
| `listen 443 ssl http2;` | Listens on port 443, decrypts the HTTPS traffic and enables HTTP/2 for faster performance. |
| `server_name ${DOMAIN_NAME};` | The domain this server answers to. `ini_ssl.sh` |
| `ssl_certificate` / `ssl_certificate_key` | Paths to the certificate and private key |
| `ssl_protocols TLSv1.2 TLSv1.3;` | Only allows these TLS versions. |
| `root /var/www/html;` | Folder with the website files. It must be the same volume WordPress uses |
| `index index.php;` | File served when a folder is requested |
| `client_max_body_size 64M;` | Maximum upload size. PHP's `upload_max_filesize` and `post_max_size` must allow it too |
 
### `location /`: the fallback route
```nginx
location / {
    try_files $uri $uri/ /index.php?$args;
}
```
This matches any URL that no more specific `location` handles. `try_files` tries three things in order:
1. A file with that exact path: serve it.
2. A folder with that path: serve it.
3. Otherwise, pass the request to WordPress's `index.php`, which handles the URL.

### `location ~ \.php`: PHP requests
```nginx
location ~ \.php {
    fastcgi_pass wordpress:9000;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
}
```
- `~ \.php` matches any URL containing `.php`.
- `fastcgi_pass wordpress:9000;` sends the request to the PHP-FPM service named `wordpress`, on port 9000.
- `include fastcgi_params;` loads the standard request variables PHP needs.
- `fastcgi_param SCRIPT_FILENAME ...` tells PHP which file to run.
