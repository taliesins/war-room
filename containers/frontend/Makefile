NAME ?= node-docker-good-defaults
NAMESPACE ?= taliesins

build:
	docker build -t $(NAMESPACE)/$(NAME) .

start: 
	docker-compose up -d

stop:
	docker-compose down

tests: 
	docker-compose exec node npm test

bash:
	docker-compose exec node bash