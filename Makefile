tag ?= djbingham/fleet-ca
container ?= fleet-ca
host ?=
privateIP ?=
publicIP ?=
cmd ?=

build:
	docker build --tag $(tag) .

push:
	docker push $(tag)

pull:
	docker pull $(tag)

generate:
	docker run \
		--rm \
		--volume "fleet-ca-certificates:/home/certificates" \
		$(tag) generateCsr $(host) $(privateIP)

	docker run \
		--rm \
		--volume "fleet-ca-certificates:/home/certificates" \
		$(tag) generateCert $(host) $(publicIP)

run:
	docker run \
		-d \
		--name "$(container)" \
		--volume "fleet-ca-certificates:/home/certificates" \
		$(tag)

logs:
	docker logs -f $(container)

destroy:
	docker stop $(container)
	docker rm -vf $(container)

bash:
	docker run \
		--rm \
		-it \
		--volume "fleet-ca-certificates:/home/certificates" \
		--entrypoint bash \
		$(tag) $(cmd)
