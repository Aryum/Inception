YML_FILE = srcs/docker-compose.yml
DATA_DIR = /home/$(USER)/data
DIRS = $(DATA_DIR)/wordpress $(DATA_DIR)/mariadb

COLOUR_GREEN := \033[1;32m
COLOUR_RED := \033[1;31m
COLOUR_YELLOW := \033[1;33m
COLOUR_BLUE := \033[1;34m
COLOR_WHITE := \033[0m

all: build up

build:
	@echo "${COLOUR_BLUE}Builiding images ${COLOR_WHITE}"
	cd && mkdir -p $(DIRS)
	docker compose -f $(YML_FILE) build

up:
	@echo "${COLOUR_GREEN}Starting containers ${COLOR_WHITE}"
	docker compose -f $(YML_FILE) up -d

down:
	@echo "${COLOUR_RED} Stoping containers ${COLOR_WHITE}"
	docker compose -f $(YML_FILE) down

clean: 
	@echo "${COLOUR_RED} Cleaning images ${COLOR_WHITE}"
	docker compose -f $(YML_FILE) down
	docker system prune -af

fclean: 
	@echo "${COLOUR_RED} Cleaning images and volumes ${COLOR_WHITE}"
	docker compose -f $(YML_FILE) down
	docker system prune -af
	docker volume prune -f
	cd && sudo rm -rf $(DATA_DIR)

re: 
	@echo "${COLOUR_RED}Rebuilding images and restarting containers${COLOR_WHITE}"
	docker compose -f $(YML_FILE) down
	docker compose -f $(YML_FILE) build
	docker compose -f $(YML_FILE) up


