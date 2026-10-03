COMPOSE = docker compose -f srcs/docker-compose.yml
DATA_DIR = /home/mel-mora/data

.PHONY: all setup build up down clean fclean re logs ps

all: up

setup:
	mkdir -p $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress

build:
	$(COMPOSE) build

up: setup
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

clean:
	$(COMPOSE) down --remove-orphans

fclean:
	$(COMPOSE) down --rmi all --volumes --remove-orphans

re:
	$(MAKE) fclean
	$(MAKE) all

logs:
	$(COMPOSE) logs --tail=100

ps:
	$(COMPOSE) ps
