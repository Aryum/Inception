*This project has been created as part of the 42 curriculum by ricsanto.*

# Inception
---

## Instructions

### Prerequisites
- A virtual machine (Linux) with sudo permissions
- Docker with Docker Compose
- Make

### 1. Clone the repository
```bash
git clone https://github.com/Aryum/Inception.git Inception
cd Inception
```

### 2. Configure the domain
The domain is not a real public domain, so map it to the local machine:
```bash
echo "127.0.0.1 ricsanto.42.fr" | sudo tee -a /etc/hosts
```

### 3. Create the secrets and the `.env` file
Neither is stored in the repository (both are git-ignored), so you must create them.

Secrets, one password per file, in `secrets/`:

| File | Contains |
|------|----------|
| `db_root_password.txt` | MariaDB root password |
| `db_admin_password.txt` | WordPress administrator password |
| `db_user_password.txt` | WordPress standard user password |
| `db_wp_password.txt` | Password the WordPress service uses to connect to the database |

Non-sensitive variables in `srcs/.env`:
```
DOMAIN_NAME=ricsanto.42.fr
MYSQL_DATABASE=<database name>
MYSQL_USER=<standard user name>
MYSQL_ADMIN=<admin user name, must not contain "admin">
WORDPRESS_DB_NAME=<database name>
WORDPRESS_DB_HOST=mariadb:3306
WORDPRESS_TABLE_PREFIX=wp_

```

### 4. Build and run
```bash
make
```
The first launch takes longer because WordPress is downloaded and MariaDB is initialized. The Makefile also creates the data folders on the host.

### 5. Access the project
- Website: https://ricsanto.42.fr
- Administration panel: https://ricsanto.42.fr/wp-admin

The certificate is self-signed, so the browser shows a warning. This is expected for a local project.

### 6. Stop and clean
| Command | Effect |
|---------|--------|
| `make down` | Stops the containers (data is kept) |
| `make up` | Starts them again |
| `make clean` | Removes images, keeps volumes |
| `make fclean` | Removes everything, including the data (**destructive**) |
| `make re` | Rebuilds and restarts |

For more detail, see [USER_DOC.md](USER_DOC.md) (using the stack) and [DEV_DOC.md](DEV_DOC.md) (development and maintenance).

---

## Project description

### Use of Docker
The project sets up a small web infrastructure with Docker Compose: an Nginx container as the only entrypoint (port 443, TLSv1.2/1.3 only), a WordPress + PHP-FPM container, and a MariaDB container. Each service has its own Dockerfile, is built on `debian:bookworm` (the penultimate stable Debian release), and runs in a dedicated container. No ready-made images are pulled.

### Sources included
```
├── Makefile                 # builds and manages everything through docker compose
├── README.md, USER_DOC.md, DEV_DOC.md
├── secrets/                 # passwords (git-ignored)
└── srcs/
    ├── docker-compose.yml   # services, network, volumes, secrets
    ├── .env                 # non-sensitive variables (git-ignored)
    └── requirements/
        ├── mariadb/         # Dockerfile, 50-server.cnf, init_db.sh
        ├── nginx/           # Dockerfile, nginx.conf, ini_ssl.sh
        └── wordpress/       # Dockerfile, www.conf, ini_wp.sh
```

### Main design choices
- **PID 1 handling:** every Dockerfile uses `ENTRYPOINT` in exec mode, and each startup script ends with `exec <service>`, so the service itself becomes PID 1 and receives signals correctly. Nginx runs with `daemon off;`.
- **Idempotent startup scripts:** each script checks what already exists (initialized database, `wp-config.php`, valid certificate) so restarting a container never overwrites data.
- **TLS:** Nginx generates a self-signed certificate at startup if none exists, and only allows TLSv1.2 and TLSv1.3.
- **Isolation:** only Nginx publishes a port. WordPress (9000) and MariaDB (3306) are reachable only inside the Docker network.
- **Passwords:** stored as Docker secrets and read from `/run/secrets/`, never in Dockerfiles or in the repository.
- **Persistence:** the database and website files live in two named volumes stored under `/home/ricsanto/data`.
- **Resilience:** containers are configured to restart after a crash.

## Docker Concepts

### Docker and Docker Compose
Docker is a tool to create and run self-contained environments, a way to develop applications with all their requirements without relying on what is on the host machine. These environments are called **containers**.

Docker Compose is another tool that allows us to run multi-container applications from a single setup file (`.yml`). It declares which services we are using, how to build them (images), how they connect (network) and how they store data (mounts). It also streamlines the setup of our images, so we don't need to run a command with a long chain of flags.

#### Containers vs VMs
Containers are lightweight because, unlike VMs, which virtualize the hardware through a hypervisor and have their own OS kernel, containers **share the host kernel** and only package the application and its dependencies.

Inside a container, the kernel makes it think it is alone on the machine. What it has access to is curated by the kernel, using:

| Feature | Purpose |
|---------|---------|
| **namespaces** | Give an isolated view of processes, network, filesystems, etc. |
| **cgroups** | Limit the resources the container can use |

Their small size allows better performance and easier sharing.

Of course, there are trade-offs. Compared to a VM, containers have weaker isolation and security, since a kernel vulnerability would give access to the host. A mix of VMs and containers is often used.

---

### Images
To build a container you need an **image**. It can be compared to a class in object-oriented programming, with the container being an instance of that class. An image is read-only and layered. To create one you use a Dockerfile with multiple instructions, each one a step that adds a layer to the image.

Docker caches these layers, reusing every layer up to the first one that changed and only rebuilding from that point forward. This is why instructions that change often should be placed **after** the ones that change rarely.

---

### Storage
When starting a container, it uses the files and configuration provided by the image. It has access to a writable layer that persists when stopping/starting it, but if the container is **removed**, this data is removed too. This is a problem if we want data to persist when a container is recreated.

There are multiple ways to persist data:

| Type | Explanation |
|------|-------------|
| **Volume mounts** | Managed by the Docker daemon, independent of the host's folder structure. Better portability, and meant to be managed through Docker commands |
| **Bind mounts** | Managed by the host system, stored in any path we set. Easier to access from the host machine but less portable. This can be dangerous because it gives the container direct access to the host filesystem |
| **tmpfs mounts** | Stored directly in the host's memory, never written to disk. Lost every time the container is stopped or restarted, and cannot be shared between containers |
| **Image mounts** | Make the contents of another image available at a chosen path. Read-only and not part of the container image |

---

### Network drivers
| Driver | Explanation |
|--------|-------------|
| `bridge` | The default. Allows containers on the same host to communicate with each other. Each has its own isolated IP and network namespace, and only the ports we set up are exposed |
| `host` | Removes the network isolation between container and host, using the host network directly. No port mapping is needed, but port conflicts are possible |
| `overlay` | Allows communication between multiple hosts |
| `macvlan` | Gives the container its own MAC address and IP on the physical LAN, so it appears as a physical device and is reachable directly without port publishing |
| `none` | Completely isolates the container from the host and from other containers |

---


### Comparisons

**Virtual Machines vs Docker**
A VM virtualizes hardware through a hypervisor and runs its own kernel, so it is heavy but strongly isolated. A container shares the host kernel and isolates processes with namespaces and cgroups, so it is lighter, faster to start and easier to share, but its isolation is weaker (a kernel vulnerability can reach the host). This project uses a VM as the host environment and Docker for the services inside it, combining both.

**Secrets vs Environment Variables**
Environment variables are simple, but values written in plain text can leak through `docker inspect`, logs and child processes. Docker secrets are mounted as read-only files in `/run/secrets/` and only given to the containers that need them. This project keeps passwords in secrets and non-sensitive values (domain name, usernames, database name) in `.env`.

**Docker Network vs Host Network**
With a user-defined bridge network, each container has its own IP and namespace, containers reach each other by service name, and only explicitly published ports are exposed. With the host network, the container shares the host's network stack: there is no isolation and port conflicts are possible. This project uses a bridge network so that only Nginx is exposed, and `network: host` is forbidden by the subject.

**Docker Volumes vs Bind Mounts**
Bind mounts map a host path directly into the container: easy to access, but less portable and they give the container direct access to the host filesystem. Docker volumes are managed by Docker and are more portable. The subject requires named volumes, but the data must be at `/home/ricsanto/data`, so the project declares named volumes with the `local` driver and `o: bind` options. They remain Docker-managed volumes while their data lands at the required host path.

---


## Project Overview

### Services
For this project we set up 3 services:

| Service | Role |
|---------|------|
| **Nginx** | The only entry point. Connects clients to the server, encrypts the connection and forwards PHP requests to WordPress |
| **WordPress** | Application layer. Runs the PHP code, is responsible for the website front end and back end, and talks to the database |
| **MariaDB** | Database server that stores the site content, users and settings. Only reachable by WordPress |

---

### Dockerfile
Each service is built with its own Dockerfile, and they follow a similar structure:
1. Pull `debian:bookworm` as the base image
2. Install the service and remove unnecessary update cache files
3. Make folders and change permissions
4. Copy config files and setup scripts
5. Run the startup script

---

### Startup script
The startup script is responsible for starting the service and checking that all required files are in place.

An important detail is **how** the service is started. The first process (PID 1) is the ancestor of every other process in the container, so it is responsible for signal handling and reaping zombie processes.

In the Dockerfile there are two ways to write `ENTRYPOINT`:

| Mode | Example | Result |
|------|---------|--------|
| **exec mode** | `ENTRYPOINT [ "path/to/start/script.sh" ]` | Runs the script directly, making it PID 1 |
| **shell mode** | `ENTRYPOINT command param1 param2` | Starts a shell first and then the command, making the shell PID 1 |

We use exec mode, and our startup scripts end with `exec <service>`, which replaces the shell with the service so the service becomes PID 1. Nginx needs a particular setting (`daemon off;`) in its config file so it runs in the foreground.

---

### Docker Compose
For easier configuration of these services we use a Docker Compose file (`.yml`), as explained earlier. It streamlines our container initialization, and lets us set up the network, volumes, environment variables and more.

#### Secrets
Our containers may have sensitive data like API keys and passwords. If they were written in plain text in the environment, they could be exposed through `docker inspect`, logs and child processes.

To avoid this, Docker has **secrets**, which pass files in read-only mode, mounted at `/run/secrets/<secret name>`. They are only granted to the containers that need them in the compose file, and are read by the service's startup script or by the service itself.

Other non-sensitive data, like the domain name and usernames, can safely stay in `.env`.

#### Volumes
Using bind mounts directly in the services is not allowed, but we still want to store data at a specific path on the host. The workaround is to declare a **named volume** with the `local` driver and set `o: bind`, so Docker uses an existing host directory as the volume's storage:

```yaml
volumes:
  db_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /path/on/host/data
```

| Option | Explanation |
|--------|-------------|
| `type: none` | Since we use an existing directory and not a new filesystem, no type is set |
| `o: bind` | Makes Docker bind an existing host directory |
| `device` | The host path where the data will live |

The volume is still managed by Docker, but the data is stored at the path we set.

---

## MariaDB Setup

| File | Purpose |
|------|---------|
| `50-server.cnf` | Server configuration (read by `mysqld` on every start) |
| `init_db.sh` | Entrypoint script: initializes the data directory, creates the database and users, then starts MariaDB |

---

### `init_db.sh` step by step

`set -e` 
makes the script stop as soon as a command fails

`database_missing()` 
checks if the data directory was initialized, setting the user to `mysql`

`mysqld --skip-networking --skip-grant-tables --socket="${SOCKET}" --user=mysql & pid="$!"`
we start a temporary server without networking, skipping permission checking so we can update password without issues. Saves the process id to be used later

`mysqladmin --socket="${SOCKET}" ping --silent --wait=30 --connect-timeout=3`
tries connection with the server, if its unsuccessful it exits with an error

`mysql --socket=${SOCKET} -u root` with here doc
sets up/updates database passwords

`timeout 30 env MYSQL_PWD="${MYSQL_ROOT_PASSWORD}" mysqladmin --socket="${SOCKET}" -u root shutdown`
sends a shutdown signal, as root user passing password through env variable so it doesn't appear on the command line

`wait "$pid" || true`
waits for the server to shutdown, || true stops set -e from stopping the script if the server returns an error

`exec mysqld --user=mysql --datadir="${DB_DIR}" --socket="${SOCKET}"`
starts the real server, making mariadb the container's main process (PID1)

---

### `50-server.cnf` options

Sets for folders for log and data folder, files for pid, log socket (file used for process communication). Also sets bind address to 0.0.0.0 so it listens on all IPv4 network interfaces and the user that the server will run as.

---

## Nginx Setup

| File | Purpose |
|------|---------|
| `nginx.conf` | Nginx configuration. It is used as a **template**  |
| `ini_ssl.sh` | Entrypoint script: fills in the domain, creates a self-signed SSL certificate if needed, tests the config, and starts nginx |

---

### Required environment variable

| Variable | Meaning |
|----------|---------|
| `DOMAIN_NAME` | Domain the site is served on. It is inserted into the config and used as the certificate's Common Name |

---

### `ini_ssl.sh` step by step

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
creates a self signed certificate, since it is not signed by a trusted certificate authority, browser cannot verify who is behind it. The connection **is encrypted** but the server's identity **is not verified**, which means it does not protect against someone impersonating the server. This is why the browser shows a warning.

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
Sets certificate permissions read/write for the owner, read-only for group and others. The private key must stay secret. The certificate is public information, so it can be readable by anyone

`nginx -t`
checks the config syntax and that the certificate and key files can be loaded

`exec nginx` 
replaces the shell with nginx, so nginx becomes the container's main process (PID 1).

---

### `nginx.conf` explained

#### Global settings
| Directive | Explanation |
|-----------|-------------|
| `user www-data;` | User the worker processes run as. |
| `daemon off;` | Keeps nginx in the foreground. |

#### `events` block
`worker_connections 1024;` is the maximum number of simultaneous connections each worker process can hold.

#### `http` block
Holds all the HTTP/HTTPS settings. `include /etc/nginx/mime.types;` maps file extensions to content types, so browsers handle each file correctly.

#### `server` block
| Directive | Explanation |
|-----------|-------------|
| `listen 443 ssl http2;` | Listens on port 443, decrypts the HTTPS traffic and enables HTTP/2 for faster performance. |
| `server_name ${DOMAIN_NAME};` | The domain this server answers to. |
| `ssl_certificate` / `ssl_certificate_key` | Paths to the certificate and private key |
| `ssl_protocols TLSv1.2 TLSv1.3;` | Only allows these TLS versions. |
| `root /var/www/html;` | Folder with the website files. It must be the same volume WordPress uses |
| `index index.php;` | File served when a folder is requested |
| `client_max_body_size 8M;` | Maximum upload size. WordPress default value |

#### `location /`: the fallback route
```nginx
location / {
    try_files $uri $uri/ /index.php?$args;
}
```
This matches any URL that no more specific `location` handles. `try_files` tries three things in order:
1. A file with that exact path: serve it.
2. A folder with that path: serve it.
3. Otherwise, pass the request to WordPress's `index.php`, which handles the URL.

#### `location ~ \.php`: PHP requests
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

---

## WordPress Setup

| File | Purpose |
|------|---------|
| `www.conf` | PHP-FPM pool configuration (who runs PHP, where it listens, how many workers) |
| `ini_wp.sh` | Entrypoint script: reads the DB password, downloads WordPress, generates `wp-config.php`, fixes permissions, and starts PHP-FPM |

---

### Required environment variables

| Variable | Meaning |
|----------|---------|
| `WORDPRESS_DB_PASSWORD_FILE` | Path to the secret file holding the database password |
| `WORDPRESS_DB_NAME` | Name of the database WordPress uses |
| `MYSQL_WORDPRESS` | Database user WordPress connects as |
| `WORDPRESS_DB_HOST` | Host (and port) of the database, normally the MariaDB service name |
| `DOMAIN_NAME` | Domain the site is served on. Used for `WP_HOME` and `WP_SITEURL` |
| `WORDPRESS_TABLE_PREFIX` | *Optional.* Prefix for the database tables, defaults to `wp_` |

---

### `ini_wp.sh` step by step

`set -e` 
makes the script stop as soon as a command fails. 

`passfile_set()`, `passfile_exists()`
check that `WORDPRESS_DB_PASSWORD_FILE` is set and that the file exists and is not empty. If not, the script exits with an error.

`wget -q https://wordpress.org/latest.tar.gz -O ${TAR_FILE}`
downloads the latest WordPress 

`cp -rn /tmp/wordpress/* "$WP_PATH" || true`
copies the files into the web folder, not overwriting existing files.

`WP_SALTS=$(wget -qO- https://api.wordpress.org/secret-key/1.1/salt/)`
gets the security salts from WordPress (random data used to make cookies and password hashes harder to crack).

`cat > "$WP_PATH/wp-config.php" << EOF`
creates the config file with a here doc, filling in the values from the env variables.

---

### `www.conf` explained
This is a PHP-FPM **pool**: a group of worker processes that run PHP code, with their own settings.

| Directive | Explanation |
|-----------|-------------|
| `[www]` | Name of the pool. It can be anything |
| `user` / `group` | User and group the workers run as. They must match the owner of the WordPress files (`www-data`) |
| `listen = 9000` | Listens on TCP port 9000. This is the port nginx uses in `fastcgi_pass wordpress:9000;` |
| `listen.owner` / `listen.group` | Owner of the socket file. Only matters when using a unix socket, not with a TCP port |

#### Process management
`pm` tells PHP-FPM how to manage its workers. It can be:
- `static`: always runs a fixed number of workers
- `dynamic`: keeps some ready and creates more if needed (used here)
- `ondemand`: keeps none up and creates them only when a request arrives

## Resources

### Documentation
- [Docker documentation](https://docs.docker.com/)
- [Nginx documentation](https://nginx.org/en/docs/)
- [MariaDB documentation](https://mariadb.com/docs/)

### Articles and tutorials
- [Textbook of Linux: PID 1 and init](https://www.textbookoflinux.com/chapter/processes/pid-1-init.html)
- [Textbook of Linux: Containers](https://www.textbookoflinux.com/chapter/containers.html)
- [Docker Nginx Wordpress Mariadb tutorial](https://dev.to/alejiri/docker-nginx-wordpress-mariadb-tutorial-inception42-1eok)
- [The Linux Process Journey: PID 1 (init)](https://medium.com/@boutnaru/the-linux-process-journey-pid-1-init-60765a069f17)
- [Docker vs VM: key differences (freeCodeCamp)](https://www.freecodecamp.org/news/docker-vs-vm-key-differences-you-should-know/)

### Videos
- [NGINX Tutorial for Beginners](https://www.youtube.com/watch?v=9t9Mp0BGnyI)
- [The Only Docker Tutorial You Need To Get Started ](https://www.youtube.com/watch?v=DQdB7wFEygo)
- [you need to learn Docker RIGHT NOW!! // Docker Containers 101]( https://www.youtube.com/watch?v=eGz9DS-aIeY)

### Use of AI
AI was used to undertsand better some docker concepts, checking config and .sh files and improve them, write readmes from notes and proofreading them.