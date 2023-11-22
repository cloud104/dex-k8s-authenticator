GOBIN=$(shell pwd)/bin
GOFILES=$(wildcard *.go)
GONAME=dex-k8s-authenticator
REGISTRY=us-docker.pkg.dev/tks-gcr-pub/tks-dex-k8s-authenticator
TAG ?= latest

all: build 

.PHONY: build
build:
	@echo "Building $(GOFILES) to ./bin"
	GOBIN=$(GOBIN) go build -o bin/$(GONAME) $(GOFILES)

.PHONY: container
container:
	@echo "Building container image"
	#docker build -t ${GONAME}:${TAG} .
	docker buildx create
	docker buildx build --push --platform linux/amd64 --platform linux/arm64 -t $(REGISTRY)/${GONAME}:${TAG} .
.PHONY: clean
clean:
	@echo "Cleaning"
	GOBIN=$(GOBIN) go clean
	rm -rf ./bin
	docker buildx prune -a -f

.PHONY: lint
lint:
	golangci-lint run

.PHONY: lint-fix
lint-fix: lint
	golangci-lint run --fix
