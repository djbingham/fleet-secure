#!/usr/bin/env bash

command="$1"
shift

if [[ "${command}" == "" ]]; then
	$( dirname ${BASH_SOURCE[0]} )/commands/generateCa
	command="auto"
fi

declare -a allowedCommands=(auto generateCa generateCsr generateCert renew)

if ! [[ ${allowedCommands[@]} =~ "${command}" ]]; then
	echo "Command should be one of the following: ${allowedCommands[@]}"
	exit 1
fi

path="$( dirname ${BASH_SOURCE[0]} )/commands/${command}"

echo "${path} $@"
