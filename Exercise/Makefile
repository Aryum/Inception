YML_FILE = scrs/docker-compose.yml
DATA_DIR = /home/$(USER)/data
DIRS = $(DATA_DIR)/wordpress $(DATA_DIR)/mariadb

all: build up

build:
	mkdir -p $(DIRS)
	docker compose -f $(YML_FILE) build

up:
	docker compose -f $(YML_FILE) up -d

down:
	docker compose -f $(YML_FILE) down

clean: down
	docker system prune -af

fclean: clean
	docker volume prune -f
	sudo rm -rf $(DATA_DIR)

re: fclean all
