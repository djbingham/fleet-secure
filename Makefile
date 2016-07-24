tag ?= djbingham/fleet-ca
container ?= fleet-ca
volume-certs ?= fleet-ca-certificates

host ?=
ip-private ?=
ip-public ?=

entrypoint ?= bash
cmd ?=

build:
	docker build --tag $(tag) .

push:
	docker push $(tag)

pull:
	docker pull $(tag)

run:
	docker run \
		-d \
		--name "$(container)" \
		--volume "$(volume-certs):/app/certificates" \
		$(tag) auto

add-certificate:
	docker run \
		--rm \
		--volume "$(volume-certs):/app/certificates" \
		$(tag) add-certificate $(host) $(ip-private) $(ip-public)

logs:
	docker logs -f $(container)

execute:
	docker run \
		--rm \
		-it \
		--volume "$(volume-certs):/app/certificates" \
		--entrypoint $(entrypoint) \
		$(tag) $(cmd)

run-command:
	docker run \
		--rm \
		--volume "$(volume-certs):/app/certificates" \
		$(tag) $(cmd)

destroy:
	docker stop $(container) || true
	docker rm -vf $(container) || true
	docker volume rm $(volume-certs) || true
