# bumpup version here.
VERSION            := 1.4
SPHINX_VERSION     := 1.8.4
USER               := makotow

# container image name and repository information
IMAGE_NAME         := sphinx-docker
TAG                := $(VERSION)-sphinx$(SPHINX_VERSION)
REGISTRY           := $(USER)/$(IMAGE_NAME)
CONTAINER_PORT     := 8000
CONTAINER_WORK_DIR := /docs/

# sphinx specific variable
DOC_DIR            := docs
WORK_DIR           := $(CURDIR)/$(DOC_DIR)

# sphinx autobuild parameters
SRC_DIR            := source
OUTPUT_DIR         := build/html
PORT               := 8000

## Shortcuts
i: init
ab: auto-build-sphinx
b: build-sphinx
c: clean

## for sphinx operation
.PHONY: init
init:
	docker run \
	-v "$(WORK_DIR)":$(CONTAINER_WORK_DIR) \
	--rm -it \
	$(REGISTRY):$(TAG) \
	sphinx-quickstart
	
.PHONY: auto-build-sphinx
auto-build-sphinx:
	docker run -p $(PORT):$(CONTAINER_PORT) \
	-v "$(WORK_DIR)":$(CONTAINER_WORK_DIR) \
	--rm -it \
	$(REGISTRY):$(TAG) \
	sphinx-autobuild --host 0.0.0.0 $(SRC_DIR) $(OUTPUT_DIR)

### Dockerfile default command is build
.PHONY: build-sphinx
build-sphinx:
	docker run \
	-v "$(WORK_DIR)":$(CONTAINER_WORK_DIR) \
	--rm -it \
	$(REGISTRY):$(TAG)

.PHONY: clean
clean: 
	docker run \
	-v "$(WORK_DIR)":$(CONTAINER_WORK_DIR) \
	--rm -it \
	$(REGISTRY):$(TAG) \
	make clean
