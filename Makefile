green := \033[32m
yellow := \033[33m
reset := \033[0m
red := \033[31m

UNAME = $(shell uname -s)
COMPOSE_PATH=./srcs/docker-compose.yml
USERNAME=tigpetro

ifeq ($(UNAME), Darwin)
	DOCKER_COMPOSE = sudo docker compose
else
	DOCKER_COMPOSE = sudo docker-compose
endif

all: up

build:
	@echo "$(yellow)===============================$(reset)"
	@echo "$(yellow)======= Building images =======$(reset)"
	@echo "$(yellow)===============================$(reset)"
	@${DOCKER_COMPOSE} -f ${COMPOSE_PATH} build
	@echo "$(yellow)=========================================$(reset)"
	@echo "$(yellow)======= Images build successfully =======$(reset)"
	@echo "$(yellow)=========================================$(reset)"

up: create_volumes build
	@echo "$(yellow)===============================$(reset)"
	@echo "$(yellow)======= Building images =======$(reset)"
	@echo "$(yellow)===============================$(reset)"
	@${DOCKER_COMPOSE} -f ${COMPOSE_PATH} up --build
	@echo "$(yellow)=========================================$(reset)"
	@echo "$(yellow)======= Images build successfully =======$(reset)"
	@echo "$(yellow)=========================================$(reset)"

up_background: create_volumes build
	@echo "$(green)==================================$(reset)"
	@echo "$(green)======= Lifting containers =======$(reset)"
	@echo "$(green)==================================$(reset)"
	@${DOCKER_COMPOSE} -f ${COMPOSE_PATH} up --build -d
	@echo "$(green)================================$(reset)"
	@echo "$(green)======= Containers ready =======$(reset)"
	@echo "$(green)================================$(reset)"

down:
	@echo "$(red)===================================$(reset)"
	@echo "$(red)======= Dropping containers =======$(reset)"
	@echo "$(red)===================================$(reset)"
	@${DOCKER_COMPOSE} -f ${COMPOSE_PATH} down
	@echo "$(red)===============================================$(reset)"
	@echo "$(red)======= Containers dropped successfully =======$(reset)"
	@echo "$(red)===============================================$(reset)"

hard_down:
	@echo "$(red)===============================================$(reset)"
	@echo "$(red)======= Dropping containers and volumes =======$(reset)"
	@echo "$(red)===============================================$(reset)"
	@${DOCKER_COMPOSE} -f ${COMPOSE_PATH} down -v
	@echo "$(red)===========================================================$(reset)"
	@echo "$(red)======= Containers and volumes dropped successfully =======$(reset)"
	@echo "$(red)===========================================================$(reset)"

start:
	@echo "$(green)===================================$(reset)"
	@echo "$(green)======= Starting containers =======$(reset)"
	@echo "$(green)===================================$(reset)"
	@${DOCKER_COMPOSE} -f ${COMPOSE_PATH} start
	@echo "$(green)==================================$(reset)"
	@echo "$(green)======= Containers started =======$(reset)"
	@echo "$(green)==================================$(reset)"


stop:
	@echo "$(red)===================================$(reset)"
	@echo "$(red)======= Stopping containers =======$(reset)"
	@echo "$(red)===================================$(reset)"
	@${DOCKER_COMPOSE} -f ${COMPOSE_PATH} stop
	@echo "$(red)==================================$(reset)"
	@echo "$(red)======= Containers stopped =======$(reset)"
	@echo "$(red)==================================$(reset)"

create_volumes:
	@echo "$(green)Creating directories for volumes$(reset)"
	@mkdir -p /home/$(USERNAME)/data
	@mkdir -p /home/$(USERNAME)/data/mariadb
	@mkdir -p /home/$(USERNAME)/data/wordpress
	@echo "$(green)Directories created successfully$(reset)"

remove_volumes:
	@echo "$(red)Deleting directories for volumes$(reset)"
	@sudo rm -rf /home/$(USERNAME)/data/mariadb
	@sudo rm -rf /home/$(USERNAME)/data/wordpress
	@sudo rm -rf /home/$(USERNAME)/data
	@sudo docker volume prune --force
	@echo "$(red)Directories deleted successfully$(reset)"

remove_all: hard_down remove_volumes
	@sudo docker system prune --all --force --volumes
	@sudo docker network prune --force
	@if [ -n "$(shell docker images -q)" ]; then \
    		sudo docker rmi -f $(shell docker images -q); \
    	else \
    		echo "No images to delete."; \
	fi

re: remove_all up

info:
	sudo docker system df

.PHONY: all build up up_background down hard_down start stop create_volumes remove_volumes remove_all re info
