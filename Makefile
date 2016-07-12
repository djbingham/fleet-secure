tag ?= djbingham/fleet-ca
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

start:
	docker run \
		-d
		--name "fleet-ca" \
		--volume "fleet-ca-certificates:/home/certificates" \
		$(tag)

generate:
	docker run \
		--rm \
		--volume "fleet-ca-certificates:/home/certificates" \
		$(tag) generateCsr $(host) $(privateIP)
	docker run \
		--rm \
		--volume "fleet-ca-certificates:/home/certificates" \
		$(tag) generateCert $(host) $(publicIP)

bash:
	docker run \
		--rm \
		-it \
		--volume "fleet-ca-certificates:/home/certificates" \
		--entrypoint bash \
		$(tag) $(cmd)

exec:
	docker exec fleet-ca" $(cmd)
