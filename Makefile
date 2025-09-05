.PHONY: build testbed

# Build the docker image
build: Dockerfile
	docker build -t dns-control-panel-php .

# Start testbed in foreground (useful for debugging)
testbed: build
	docker-compose -f testbed/compose.yml up
