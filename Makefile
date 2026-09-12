SHELL := /bin/sh

# Override with DOCKER="sudo docker" when the current user cannot access the
# Docker daemon directly.
DOCKER ?= docker

IMAGE ?= grav:local
CONTAINER ?= grav-smoke-test
PLATFORM ?= linux/amd64
PORT ?= 18080
WAIT_SECONDS ?= 30

.PHONY: help build config-test run stop logs test test-arm64

help:
	@echo "Available targets:"
	@echo "  build        Build the image for PLATFORM (default: linux/amd64)"
	@echo "  config-test  Validate nginx and PHP-FPM configuration"
	@echo "  run          Run the image in the background"
	@echo "  stop         Remove the test container"
	@echo "  logs         Show test container logs"
	@echo "  test         Build and run the smoke tests"
	@echo "  test-arm64   Build and run smoke tests for linux/arm64"

build:
	$(DOCKER) buildx build --platform $(PLATFORM) --tag $(IMAGE) --load .

config-test: build
	$(DOCKER) run --rm --platform $(PLATFORM) $(IMAGE) nginx -t
	$(DOCKER) run --rm --platform $(PLATFORM) $(IMAGE) php-fpm -t

run: build
	-$(DOCKER) rm -f $(CONTAINER)
	$(DOCKER) run --detach --name $(CONTAINER) --publish $(PORT):8080 --platform $(PLATFORM) $(IMAGE)

stop:
	-$(DOCKER) rm -f $(CONTAINER)

logs:
	$(DOCKER) logs $(CONTAINER)

test: config-test
	@set -eu; \
	command -v curl >/dev/null 2>&1 || { echo "curl is required on the host" >&2; exit 1; }; \
	$(DOCKER) rm -f $(CONTAINER) >/dev/null 2>&1 || true; \
	cleanup() { $(DOCKER) rm -f $(CONTAINER) >/dev/null 2>&1 || true; }; \
	trap cleanup EXIT INT TERM; \
	$(DOCKER) run --detach --name $(CONTAINER) --publish $(PORT):8080 --platform $(PLATFORM) $(IMAGE) >/dev/null; \
	uid=$$($(DOCKER) exec $(CONTAINER) id -u); \
	if [ "$$uid" -eq 0 ]; then \
		echo "The container is running as root (UID 0)" >&2; \
		exit 1; \
	fi; \
	ready=0; \
	i=0; \
	while [ $$i -lt $(WAIT_SECONDS) ]; do \
		if $(DOCKER) exec $(CONTAINER) curl --fail --silent http://127.0.0.1:8080/fpm-ping >/dev/null 2>&1; then \
			ready=1; \
			break; \
		fi; \
		i=$$((i + 1)); \
		sleep 1; \
	done; \
	if [ $$ready -ne 1 ]; then \
		echo "The container did not become ready within $(WAIT_SECONDS) seconds" >&2; \
		$(DOCKER) logs $(CONTAINER); \
		exit 1; \
	fi; \
	curl --fail --silent --show-error --location http://127.0.0.1:$(PORT)/ >/dev/null; \
	$(DOCKER) exec $(CONTAINER) curl --fail --silent http://127.0.0.1:8080/fpm-ping >/dev/null; \
	echo "Smoke tests passed for $(PLATFORM)";

test-arm64:
	$(MAKE) PLATFORM=linux/arm64 IMAGE=$(IMAGE)-arm64 test
