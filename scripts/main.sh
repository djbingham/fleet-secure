#!/usr/bin/env bash
. $(dirname ${BASH_SOURCE[0]})/functions.sh

command="$1"
shift

if [ ${command} == "" ]; then
	command="auto"
fi

declare -a allowedCommands=(auto add-certificate)

if ! [[ ${allowedCommands[@]} =~ "${command}" ]]; then
	echo "ERROR: Command should be one of the following: ${allowedCommands[@]}."
	exit 1
fi

if [ ${command} == "auto" ]; then
	initialiseCA
	autoRenewCertificates
elif [ ${command} == "add-certificate" ]; then
	createCSR $@
	generateCertificate $@
	deployCertificate $@
fi
