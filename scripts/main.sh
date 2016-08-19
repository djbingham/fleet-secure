#!/usr/bin/env bash
. $(dirname ${BASH_SOURCE[0]})/functions.sh

command="$1"
shift

if [[ ${command} == "" ]]; then
	command="auto"
fi

echo "Running command '${command}'"
case ${command} in
	auto)
		initialiseCA
		automate 10 renewAllCertificates
		;;

	add-certificate)
		createCSR $@
		generateCertificate $@
		deployCertificate $@
		;;

	*)
		declare -a allowedCommands=(auto add-certificate)
		echo "Command not recognised. Allowed commands are: ${allowedCommands[@]}"
		;;
esac
