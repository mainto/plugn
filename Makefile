NAME = plugn
HARDWARE = $(shell uname -m)
VERSION ?= 0.2.1
IMAGE_NAME ?= $(NAME)
BUILD_TAG ?= dev

build:
	go-bindata bashenv
	mkdir -p build/linux  && GOOS=linux  go build -a -ldflags "-X main.Version $(VERSION)" -o build/linux/$(NAME)

deps:
	go get || true

release: build
	rm -rf release && mkdir release
	tar -zcf release/$(NAME)_$(VERSION)_linux_$(HARDWARE).tgz -C build/linux $(NAME)

build-in-docker:
	docker build --rm -f Dockerfile.build -t $(NAME)-build .
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock:ro \
		-v /var/lib/docker:/var/lib/docker \
		-v ${PWD}:/usr/src/myapp -w /usr/src/myapp \
		-e IMAGE_NAME=$(IMAGE_NAME) -e BUILD_TAG=$(BUILD_TAG) -e VERSION=master \
		$(NAME)-build make -e deps build
	docker rmi $(NAME)-build || true

test:
	basht tests/*/tests.sh

circleci:
	docker version
	rm -f ~/.gitconfig
	mv Dockerfile.dev Dockerfile

clean:
	rm -rf build/*
	docker rm $(shell docker ps -aq) || true
	docker rmi plugn:dev || true

.PHONY: build release deps build-in-docker clean test circleci
