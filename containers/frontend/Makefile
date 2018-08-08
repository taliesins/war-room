NAME ?= node-docker-good-defaults

build:
	docker build -t $(NAME) .

start: 
	docker-compose up -d

stop:
	docker-compose down

tests: 
	docker-compose exec node npm test

bash:
	docker-compose exec node bash