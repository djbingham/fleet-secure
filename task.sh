#!/usr/bin/env bash
##
## Usage: _PROG_
##
## This is an unofficial utility to create and automate renewal of certificates for CoreOS fleet members,
## enabling TLS encryption to be setup and maintained between fleet members with minimal effort.
##
## All arguments have default values, which are defined at the top of _PROG_, but can be overridden.
## Their usage is described below, in the documentation for each available task.
##

. $(dirname ${BASH_SOURCE[0]})/scripts/functions.sh

# Task to execute from this script
task=''

# Fleet-wide arguments
tag='djbingham/fleet-certificate-authority'
container='fleet-certificate-authority'
certificateVolume="$(pwd)/certificates"

# Host-specific arguments
commonName='fleet'
hosts="\"${COREOS_PRIVATE_IPV4}\", \"${COREOS_PUBLIC_IPV4}\""

# Command to execute in container
command=''
arguments=''

# Override defaults from above with any options passed via command line
getOptions $*

# Build volume arguments for Docker commands
volumeNames="${certificateVolume}"
volumeArguments="--volume ${certificateVolume}:/app/certificates"

if [[ "${ENVIRONMENT}" == 'development' ]]; then
	volumeNames="${volumeNames}"
	volumeArguments="${volumeArguments} --volume $(pwd)/scripts:/app/scripts"
	volumeArguments="${volumeArguments} --volume $(pwd)/config:/app/config"
fi

echo ""
echo "Executing task '${task}' with volumes: ${volumeArguments}."

## Available tasks
case ${task} in

	##
	##> build
	##>> Build the container image.
	##
	##>> Allowed arguments:
	##>>> tag: The tag to apply to the built container image.
	build)
		docker build --tag ${tag} .
		;;

	##
	##> push
	##>> Push the container image to the repository.
	##
	##>> Allowed arguments:
	##>>> tag: The tag of the container image to push.
	push)
		docker push ${tag}
		;;

	##
	##> pull
	##>> Pull the container image from the repository.
	##
	##>> Allowed arguments:
	##>>> tag: The tag of the container image to pull.
	pull)
		docker pull ${tag}
		;;

	##
	##> logs
	##>> Tail the logs from the running container.
	##
	##>> Allowed arguments:
	logs)
		docker logs -f ${container}
		;;

	##
	##> start
	##>> Run the container with the default command.
	##
	##>> Allowed arguments:
	##>>> container: Name to assign the container.
	##>>> certificateVolume: Name of the volume in which generated certificates should be stored.
	##>>> tag: The tag of the container image to run.
	start)
		docker run \
			-d \
			--name "${container}" \
			${volumeArguments} \
			${tag}
		;;

	##
	##> stop
	##>> Stop (if running) and destroy a container.
	##
	##>> Allowed arguments:
	##>>> container: Name of the container to destroy.
	##>>> certificateVolume: Name of the volume in which generated certificates should be stored.
	stop)
		docker stop ${container} || true
		docker rm -vf ${container} || true
		docker volume rm ${volumeNames} || true
		;;

	##
	##> generate-ca
	##>> Generate and deploy a new certificate to a fleet node.
	##
	##>> Allowed arguments:
	##>>> certificateVolume: Name of the volume in which generated certificates should be stored.
	##>>> tag: The tag of the container image to run.
	generate-ca)
		docker run \
			--rm \
			${volumeArguments} \
			${tag} generate-ca
		;;

	##
	##> generate-certificate
	##>> Generate and deploy a new certificate to a fleet node.
	##
	##>> Allowed arguments:
	##>>> certificateVolume: Name of the volume in which generated certificates should be stored.
	##>>> tag: The tag of the container image to run.
	##>>> commonName: The common name to assign to the generated certificate.
	##>>> hosts: The host names and IP address the certificate should be valid for.
	generate-certificate)
		if [[ ${commonName} == "" || ${hosts} == "" ]]; then
			echo 'Missing required option. Required: commonName, hosts'
		else
			docker run \
				--rm \
				${volumeArguments} \
				${tag} generate-certificate ${commonName} ${hosts}
		fi
		;;

	##
	##> execute
	##>> Execute an arbitrary command within the Fleet CA container. Container must be running before this is called.
	##
	##>> Allowed arguments:
	##>>> certificateVolume: Name of the volume in which generated certificates should be stored.
	##>>> tag: The tag of the container image to run.
	##>>> command (or cmd): The command to execute inside the container
	execute)
	echo "EXECUTING ${command} $arguments}"
		docker exec \
			-it \
			${container} ${command} ${arguments}
		;;

	##
	##> help
	##>> Print this help documentation.
	help)
		file="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/`basename ${BASH_SOURCE[0]}`"
		docs=''
		grep '^[[:space:]]*##' "$file" | while read -r line; do
			indentLevel=$(echo ${line} | sed 's/##\(>*\)/\1/g' | awk '{ print length }')
			indent=$(printf '\t'{1..${indentLevel})
			echo ${line} | sed -e 's/^[[:space:]]*##//' -e 's/>/    /g' -e "s|_PROG_|$file|" 1>&2
		done
		;;

	*)
		echo "Command not recognised."
		;;
esac
