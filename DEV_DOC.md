# Developer Documentation

A guide on how to set up, build, run and maintain this project from scratch.

## 1. Setting up the environment from scratch
### Prerequisites
 - Virtual Machine
 - Docker with Docker compose
 - Make
 - Sudo permissions

### Host preparation
 - Add 127.0.0.1 ricsanto.42.fr to /etc/hosts

### Repository layout
```
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/                  # git-ignored
│   ├── db_admin_password.txt
│   ├── db_root_password.txt
│   ├── db_user_password.txt
│   └── db_wp_password.txt
└── srcs/
    ├── docker-compose.yml
    ├── .env                  # git-ignored
    └── requirements/
        ├── mariadb/   (Dockerfile, conf/, tools/)
        ├── nginx/     (Dockerfile, conf/, tools/)
        └── wordpress/ (Dockerfile, conf/, tools/)
```

### Configuration file: `srcs/.env`

### Env
| Variable | Purpose | Example |
|----------|---------|---------|
| IMAGE_DIR | Folder with compose file | /requirements |
| DOMAIN_NAME | Site domain | login.42.fr |
| MYSQL_DATABASE | WordPress DB name | name |
| MYSQL_USER | Standard user of WordPress DB  | name |
| MYSQL_ADMIN | Admin user of WordPress DB (must not contain "admin") | name |
| WORDPRESS_DB_NAME | Database name for wordpress | wordpress_db |
| WORDPRESS_DB_HOST | Database service used for wordpress | mariadb |
| WORDPRESS_TABLE_PREFIX | Prefix used to id WP datbase tables | wp_ |

### Secrets
| File | Contains |
|------|----------|
| db_admin_password.txt | wordpress database admin password |
| db_root_password.txt | database root password |
| db_user_password.txt | wordpress database user password |
| db_wp_password.txt | wordpress database service password |

They are declared on the secrets block in the docker-compose.yml, which will be passed to the containers that need it and accessed by reading /run/secrets/**name**


## 2. Building and launching the project

### Makefile targets
| Target | Description |
|--------|-------------|
| make / make all | Builds and starts containers, creating necessary folders for volumes on host |
| make build | Builds containers |
| make up | Starts containers |
| make down  | Stops containers |
| make clean  | Cleans images leaving volumes |
| make fclean  | Cleans everything including volumes |
| make re | Rebuilds and Restarts containers |

## 3. Managing containers and volumes

### Containers
```bash
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml logs -f <service>
docker compose -f srcs/docker-compose.yml exec <service> <command>
docker compose -f srcs/docker-compose.yml restart <service>
docker compose -f srcs/docker-compose.yml down
```

### Images Volumes and network
```bash
docker images
docker volume ls
docker volume inspect <volume_name>
docker network ls
docker network inspect <network_name>
```

### Database management
```bash
#enter mariadb in interactive mode
docker exec -it mariadb mariadb -u <username> -p

#display all databases
SHOW DATABASES;

#select database
USE <database_name>;

#display tables from database
SHOW TABLES;

#display info stored in table
SELECT * FROM <table> LIMIT 5\G

#create new user
CREATE USER <name>@<ip> IDENTIFIED BY <password>;

#check users of database
SELECT User, Host From mysql.user

#show permissions of user ip
SHOW GRANTS FOR <name>@<ip>

#grant or remove permissions
GRANT <permission> ON <database>-* FROM <name>@<ip>
REVOKE <permission> ON <database>-* FROM <name>@<ip>
#save permissions saves 
FLUSH PRIVILEDGES
```


### Full reset (**destructive**)
```bash
make fclean
make all
```

## 4. Data storage and persistence

| Volume | Container path | Host path | Contains |
|--------|----------------|-----------|----------|
| mariadb_data | `/var/lib/mysql` | `/home/ricsanto/data/mariadb` | Database |
| wordpress_data | `/var/www/html` | `/home/ricsanto/data/wordpress` | Website files |

### How the volumes are defined
These are **Docker named volumes**, work similarly to bind mounts, as they are still stored in a specified path (`/home/ricsanto/data`), but they can still be managed by docker. They are configured like this:

```yaml
volumes:
  volume name:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/ricsanto/data/service_name
```

### Persistence behaviour
| Event | Data kept? |
|-------|-----------|
| Container crash / automatic restart | yes |
| `make down` | yes |
| `make fclean` | no |
| Host reboot | yes |
