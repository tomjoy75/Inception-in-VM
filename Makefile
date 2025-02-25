LOGIN := $(shell whoami)

WP_DATA = /home/$(LOGIN)/data/wordpress #define the path to the wordpress data
DB_DATA = /home/$(LOGIN)/data/mariadb #define the path to the mariadb data

# default target
all: up

# start the biulding process
# create the wordpress and mariadb data directories.
# start the containers in the background and leaves them running
up: build
	@mkdir -p $(WP_DATA)
	@mkdir -p $(DB_DATA)
	@sudo chown -R $(LOGIN):$(LOGIN) $(WP_DATA) $(DB_DATA) 
	@sudo chmod 755 $(DB_DATA) $(WP_DATA) 
# @chown -R tjoyeux:tjoyeux $(WP_DATA)
	@echo "🚀 Starting containers..."
	docker compose -p inception -f ./srcs/docker-compose.yml up -d --remove-orphans

# bonus: down
# 	@echo "🚀 Starting base containers..."
# 	@docker compose -f ./srcs/docker-compose.yml up -d --build
# 	@echo "🚀 Starting bonus containers..."
# 	@docker compose -f ./srcs/docker-compose.bonus.yml up -d --build

# Add network creation to ensure it exists
create-network:
	@echo "🌐 Creating Docker network..."
	@docker network create inception || true

bonus: down create-network
	@echo "🚀 Starting all containers..."
	@docker compose -p inception\
	    -f ./srcs/docker-compose.yml \
	    -f ./srcs/docker-compose.bonus.yml \
	    up -d --build

down:
	@echo "🛑 Stopping all containers..."
	@docker compose -p inception\
	    -f ./srcs/docker-compose.yml \
	    -f ./srcs/docker-compose.bonus.yml \
	    down --remove-orphans
# down:
# 	@echo "🛑 Stopping all containers"
# 	docker compose -f ./srcs/docker-compose.bonus.yml down || true
# 	docker compose -f ./srcs/docker-compose.yml down
#	@echo "Stopping containers..."
#	docker-compose -f ./srcs/docker-compose.yml down --remove-orphans || (sudo docker-compose -f ./srcs/docker-compose.yml down --remove-orphans)

# stop the containers
stop:
	@echo "🛑 Stopping bonus containers"
	docker compose -f ./srcs/docker-compose.bonus.yml stop || true
	@echo "🛑 Stopping mandatory containers"
	docker compose -f ./srcs/docker-compose.yml stop

# start the containers
start:
#	docker compose -f ./srcs/docker-compose.yml start
	@echo "🚀 Starting mandatory containers"
	docker compose -f ./srcs/docker-compose.yml start
	@echo "🚀 Starting bonus containers"
	docker compose -f ./srcs/docker-compose.bonus.yml start || true


# build the containers
build:
	@echo "🏗️ Building mandatory containers"
	docker compose -f ./srcs/docker-compose.yml build
# build:
# 	@echo "🏗️ Building mandatory containers"
# 	docker compose -f ./srcs/docker-compose.yml build
# 	@echo "🏗️ Building bonus containers"
# 	docker compose -f ./srcs/docker-compose.bonus.yml build || true


# clean the containers
# stop all running containers and remove them.
# remove all images, volumes and networks.
# remove the wordpress and mariadb data directories.
# the (|| true) is used to ignore the error if there are no containers running to prevent the make command from stopping.


# clean the containers
clean:
	@echo "🧹 Stopping and removing containers..."
	@docker compose -p inception \
        -f ./srcs/docker-compose.yml \
        -f ./srcs/docker-compose.bonus.yml \
        down --volumes --remove-orphans || true
	# @docker compose -f ./srcs/docker-compose.bonus.yml down --volumes --remove-orphans || true
	# @docker compose -f ./srcs/docker-compose.yml down --volumes --remove-orphans || true
	@echo "🗑️  Cleaning network..."
	@docker network rm inception || true
	@echo "🗑️  Pruning Docker system..."
	@docker volume rm mariadb wordpress || true
	@docker system prune -af || true
	@echo "🧨 Cleaning data directories..."
	@sudo rm -rf $(WP_DATA)
	@sudo rm -rf $(DB_DATA)
	@echo "📁 Recreating empty directories..."
	@mkdir -p $(WP_DATA)
	@mkdir -p $(DB_DATA)
	@sudo chown -R $(LOGIN):$(LOGIN) $(WP_DATA) $(DB_DATA)
	@sudo chmod 755 $(WP_DATA) $(DB_DATA)
	@echo "✨ Clean complete!"


#@docker compose -f ./srcs/docker-compose.yml down --volumes --remove-orphans || true
#@docker system prune -af || true
#@if [ -d "$(WP_DATA)" ]; then \
#    sudo rm -rf $(WP_DATA); \
#fi
#@if [ -d "$(DB_DATA)" ]; then \
#    sudo rm -rf $(DB_DATA); \
#fi

#	@docker stop $$(docker ps -qa) || true
#	@docker rm $$(docker ps -qa) || true
#	@docker rmi -f $$(docker images -qa) || true
#	@docker volume rm $$(docker volume ls -q) || true
#	@docker network rm $$(docker network ls -q) || true
 
#	@if [ $$(docker ps -q) ]; then \
#		docker stop $$(docker ps -q); \
#	fi
#	@if [ $$(docker ps -aq) ]; then \
#	    docker rm $$(docker ps -aq); \
#	fi
#	@if [ $$(docker images -q) ]; then \
#	    docker rmi -f $$(docker images -q); \
#	fi
#	@if [ $$(docker volume ls -q) ]; then \
#	    docker volume rm $$(docker volume ls -q); \
#	fi
#	@if [ $$(docker network ls -q -f "name=inception") ]; then \
#	    docker network rm $$(docker network ls -q -f "name=inception"); \
#	fi
#	@sudo rm -rf $(WP_DATA) || true
#	@sudo rm -rf $(DB_DATA) || true

# clean and start the containers
re: clean up

# prune the containers: execute the clean target and remove all containers, images, volumes and networks from the system.
prune: clean
	@echo "♻️  Pruning all Docker resources"
	@docker system prune -a --volumes -f

.PHONY: all up down stop start build clean re prune bonus create-network

# Commands
# curl -k https://localhost
# curl -k https://tjoyeux.42.fr
# curl -k https://localhost/wp-admin
# curl -k https://localhost/adminer

# Check container
# docker logs redis

# How to know which port  by container

# Connect to Redis container and test connection
# docker exec -it redis bash
# redis-cli ping  # Should return PONG
# exit

# docker exec redis redis-cli info stats | grep hits

# Modifier MariaDB pour checker redis
# docker exec -it mariadb bash
# mysql -u root -p
# USE database_name;
# SHOW TABLES; 
# SELECT comment_author, comment_content FROM wp_comments;
# UPDATE wp_comments SET comment_content = 'commentaire modifie' WHERE comment_author = 'user_name';

# Database operations:
# docker exec -it mariadb mysql -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DB
# Common MySQL commands:
#   SHOW TABLES;
#   SELECT * FROM wp_users;
#   SELECT * FROM wp_posts LIMIT 5;

# Redis operations:
# docker exec -it redis redis-cli
# Common Redis commands:
#   PING
#   INFO
#   MONITOR
#   KEYS *

# Container management:
# docker logs -f wordpress         # Follow WordPress logs
# docker logs -f nginx            # Follow Nginx logs
# docker exec -it nginx bash      # Shell into nginx
# docker exec -it wordpress bash  # Shell into WordPress

# Network debugging:
# docker network inspect inception
# docker port nginx               # Show port mappings
# docker stats                    # Monitor container resources