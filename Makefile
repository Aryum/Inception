include srcs/.env
YML_FILE = srcs/docker-compose.yml
DATA_DIR = /home/$(USER)/data
DIRS := $(DATA_DIR)/wordpress $(DATA_DIR)/mariadb
HOST := "127.0.0.1 $(DOMAIN_NAME)"
PASS_FILES :=	secrets/db_root_pass.txt	\
				secrets/db_wp_pass.txt		\
				secrets/wp_basic_pass.txt	\
				secrets/wp_admin_pass.txt



COLOUR_GREEN := \033[1;32m
COLOUR_RED := \033[1;31m
COLOUR_YELLOW := \033[1;33m
COLOUR_BLUE := \033[1;34m
COLOR_WHITE := \033[0m

all: build up

build: $(PASS_FILES)
	@echo "${COLOUR_BLUE}Builiding images ${COLOR_WHITE}"
	grep -qs $(HOST) /etc/hosts || (echo $(HOST) | sudo tee -a /etc/hosts)
	cd && mkdir -p $(DIRS)
	docker compose -f $(YML_FILE) build

secrets/%.txt:
	mkdir -p secrets
	openssl rand -out  $@ -base64 5

up:
	@echo "${COLOUR_GREEN}Starting containers ${COLOR_WHITE}"
	docker compose -f $(YML_FILE) up -d

down:
	@echo "${COLOUR_RED} Stoping containers ${COLOR_WHITE}"
	docker compose -f $(YML_FILE) down

logs:
	docker compose -f $(YML_FILE) logs -f

clean: 
	@echo "${COLOUR_RED} Cleaning images ${COLOR_WHITE}"
	docker compose -f $(YML_FILE) down
	docker compose -f $(YML_FILE) rm -sf

fclean: 
	@echo "${COLOUR_RED} Cleaning images and volumes ${COLOR_WHITE}"
	docker compose -f $(YML_FILE) rm -sfv
	cd && sudo rm -rf $(DATA_DIR)

re: 
	@echo "${COLOUR_RED}Rebuilding images and restarting containers${COLOR_WHITE}"
	docker compose -f $(YML_FILE) rm -sf
	docker compose -f $(YML_FILE) build
	docker compose -f $(YML_FILE) up -d

.PHONY: test all build up down clean fclean re FORCE


