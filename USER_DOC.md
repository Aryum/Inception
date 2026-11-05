# User Documentation

A quick guide on how to use and administer this project's services. No previous knowledge about docker or any of it's services required.

## 1.Services provided

This project runs a WordPress website, served safely through HTTPS.

| Service | Role | Exposed to outside |
|---------|------|--------------------|
| Nginx | Web server, handles HTTPS | Yes port 443 |
| Wordpress + php-fpm | Runs website | No |
| MariaDB | Storing Website data | No |

**How they connect** Browser -> Nginx (443) -> Wordpress (9000) -> MariaDB (3306)

**Data**:
 - Database files -> /home/ricsanto/data/mariadb
 - Website files -> /home/ricsanto/data/wordpress

## 2.Starting and stopping the project

Run from Home/Desktop/Inception

| Action | Command | What it does |
|--------|---------|--------------------|
| Build and start | make / make all| Builds and starts containers |
| Build  | make build | Builds containers |
| Start | make up | Starts services |
| Stop | make down| Stops services |
| Clean Build | make clean | Cleans temporary data |
| Full Clean | make fclean | Cleans everything |
| Remake | make re | Rebuilds and Restarts services |

**First launch** It will take longer since wordpress and mariadb need to download and setup some aditional files

## 3.Accessing the website and administration panel

**Domain setup (one time)** since our website isn't a real public domain, DNS cannot resolve it. To make it work locally we need to add this line to /etc/hosts:
```
127.0.0.1   ricsanto.42.fr
```
127.0.0.1 is the loopback adress meaning the same machine

### URL
 - Website: https://ricsanto.42.fr
 - Admin page: https://ricsanto.42.fr/wp-admin

The certificate is self-signed, so the browser will show a warning, since it cannot verify the certificate with a trusted authority. This warning can be safely ignored since its a local project.


## 4.Locating and managing credentials

| Info | Location |
|------|----------|
| Non-sensitive | srcs/.env |
| Passwords | secrets/db_admin_password.txt, secrets/db_root_password.txt, secrets/db_user_password.txt, db_wp_password.txt|

**Existing accounts**
 - Mariadb
  - Root
  - Wordpress
 - Wordpress database
  - master
  - viewer
 - Wordpress website
  - ricsanto
  - santoric


**Changing a password**
1. Edit corresponding password file in 'secrets/'
2. Run "Make re" to apply password changes
note: these files are only present in the VM

## 5.How to check if the services are running correctly
- docker ps / docker compose ps to check the images that are running
- docker logs <container> to check logs
