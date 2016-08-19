#!/usr/bin/env bash

##
## Usage: _PROG_
##
## This script will execute tasks against a Fleet Certificate Authority (aka Fleet CA) container.
## This is an unofficial helper to automate creation of certificates for all members of a CoreOS fleet,
## enabling TLS encryption to be setup and maintained between fleet members with a minimum of hassle.
##
## The following arguments have default values, which are defined at the top of _PROG_, but can be overridden.
## Their usage is described below, in the documentation for each available task.
##
##> tag
##> container
##> certificateVolume
##

# Task to execute from this script
task='help'

# Fleet-wide arguments
tag='djbingham/fleet-certificate-authority'
container='fleet-certificate-authority'
certificatesVolume='fleet-certificates'

# Host-specific arguments
host=''
privateIP=''
publicIP=''

# Command to execute in container
entrypoint=''
command=''


while [[ $# -gt 0 ]]
do
	key="$1"

	case ${key} in
		--tag)
			tag="$2"
			shift # past argument name
			;;

		--container)
			container="$2"
			shift # past argument name
			;;

		--certificatesVolume)
			certificatesVolume="$2"
			shift # past argument name
			;;

		--host)
			host="$2"
			shift # past argument name
			;;

		--privateIP)
			privateIP="$2"
			shift # past argument name
			;;

		--publicIP)
			publicIP="$2"
			shift # past argument name
			;;

		--entrypoint)
			entrypoint="$2"
			shift # past argument name
			;;

		--cmd,--command)
			command="$2"
			shift # past argument name
			;;

		*)
			if [[ ${task} == 'help' ]]; then
				task="${key}"
			else
				echo "Unrecognised option given: ${key}."
			fi
			;;
	esac
	shift # past argument value (or name, if argument has no value in above case list)
done

echo ""
echo "Executing task '${task}'."

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
	##> run
	##>> Run the container with the default command.
	##
	##>> Allowed arguments:
	##>>> container: Name to assign the container.
	##>>> certificateVolume: Name of the volume in which generated certificates should be stored.
	##>>> tag: The tag of the container image to run.
	run)
		docker run \
			-d \
			--name "${container}" \
			--volume "${certificatesVolume}:/app/certificates" \
			${tag}
		;;

	##
	##> test
	##>> Run the container with the default command.
	##
	##>> Allowed arguments:
	##>>> container: Name to assign the container.
	##>>> certificateVolume: Name of the volume in which generated certificates should be stored.
	##>>> tag: The tag of the container image to run.
	test)
		docker run \
			-d \
			--name "${container}" \
			--volume "${certificatesVolume}:/app/certificates" \
			--volume "$(pwd)/scripts:/app/scripts" \
			--volume "$(pwd)/config:/app/config" \
			${tag}
		;;

	##
	##> add-certificate
	##>> Generate and deploy a new certificate to a fleet node.
	##
	##>> Allowed arguments:
	##>>> certificateVolume: Name of the volume in which generated certificates should be stored.
	##>>> tag: The tag of the container image to run.
	##>>> host: The hostname to assign to the generated certificate.
	##>>> privateIP: The private IP address of the fleet node this certificate will be deployed to.
	##>>> publicIP: The public IP address of the fleet node this certificate will be deployed to.
	add-certificate)
		docker run \
			--rm \
			--volume "${certificatesVolume}:/app/certificates" \
			${tag} add-certificate ${host} ${privateIP} ${publicIP}
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
	##> execute
	##>> Execute a command within a container sharing volumes and image with the running Fleet CA container.
	##
	##>> Allowed arguments:
	##>>> certificateVolume: Name of the volume in which generated certificates should be stored.
	##>>> tag: The tag of the container image to run.
	##>>> entrypoint: The entrypoint instruction to pass to the docker run command.
	##>>> command (or cmd): The cmd instruction to pass to the docker run command.
	execute)
		docker run \
			--rm \
			-it \
			--volume "${certificatesVolume}:/app/certificates" \
			--entrypoint ${entrypoint} \
			${tag} ${command}
		;;

	##
	##> exec
	##>> Execute a command within the running Fleet CA container.
	##
	##>> Allowed arguments:
	##>>> certificateVolume: Name of the volume in which generated certificates should be stored.
	##>>> tag: The tag of the container image to run.
	##>>> entrypoint: The entrypoint instruction to pass to the docker run command.
	##>>> command (or cmd): The cmd instruction to pass to the docker run command.
	exec)
		docker run \
			--rm \
			-it \
			--volume "${certificatesVolume}:/app/certificates" \
			--entrypoint ${entrypoint} \
			${tag} ${command}
		;;

	##
	##> destroy
	##>> Stop (if running) and destroy a container.
	##
	##>> Allowed arguments:
	##>>> container: Name of the container to destroy.
	##>>> certificateVolume: Name of the volume in which generated certificates should be stored.
	destroy)
		docker stop ${container} || true
		docker rm -vf ${container} || true
		docker volume rm ${certificatesVolume} || true
		;;

	##
	##> help
	##>> Print this help documentation.
	help)
		file=`basename "$0"`
		docs=''
		grep '^[[:space:]]*##' "$0" | while read -r line; do
			indentLevel=$(echo ${line} | sed 's/##\(>*\)/\1/g' | awk '{ print length }')
			indent=$(printf '\t'{1..${indentLevel})
			echo ${line} | sed -e 's/^[[:space:]]*##//' -e 's/>/    /g' -e "s/_PROG_/$file/" 1>&2
		done
		;;

	*)
		echo "Command not recognised."
		;;
esac