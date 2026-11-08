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

### URL 
 - Website: https://ricsanto.42.fr
 - Admin page: https://ricsanto.42.fr/wp-admin

The certificate is self-signed, so the browser will show a warning, since it cannot verify the certificate with a trusted authority. This warning can be safely ignored since its a local project.


## 3.Locating and managing credentials

| Info | Location |
|------|----------|
| Non-sensitive | srcs/.env |
| Passwords | secrets |

**Existing accounts**
 - Mariadb
  - Root
  - Wordpress
 - Wordpress website
  - ricsanto (can be changed in env)
  - santoric (can be changed in env)

## 4.How to check if the services are running correctly
- docker ps / docker compose ps to check the images that are running
- make logs to check logs
