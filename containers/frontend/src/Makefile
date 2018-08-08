NAME ?= frontend
INSTANCE ?= frontend-instance
CONTAINER-EXPOSED-PORT ?= 8080
PROXY-PORT ?= 32500
HOST ?= localhost

install:
	npm install

build:
	docker build -t $(NAME) .

run: build
	docker run -it --rm --entrypoint /bin/ash $(NAME) 

start: build
	docker run -i -t --name $(INSTANCE) -p $(PROXY-PORT):$(CONTAINER-EXPOSED-PORT) -d $(NAME)

log:
	docker logs $(INSTANCE)

bash:
	docker exec -it $(INSTANCE) /bin/ash

stop:
	docker stop $(INSTANCE) && docker rm $(INSTANCE)