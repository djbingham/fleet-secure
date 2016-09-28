#!/usr/bin/env bash
. $(dirname ${BASH_SOURCE[0]})/functions.sh

command="$1"
shift

if [[ ${command} == "" ]]; then
	command="auto"
fi

echo "Running command '${command}'"
case ${command} in
	generate-ca)
		generateCA
		;;

	##
	##> auto
	##>> Continually monitor and automatically renew all certificates generated using `add-certificate`.
	##>> This includes certificates added after the `auto` command was started.
	auto)
		# @todo: Massively reduce the frequency of renewal checks (to something like once per week or month)
		automate 10 renewAllCertificates
		;;

	##
	##> add-certificate
	##>> Generate and deploy the initial certificate for a new host.
	##>> This will be automatically renewed before expiry if there is a running `auto` command.
	##
	##>> Expected arguments:
	##>>> hostName
	##>>> publicIP
	##>>> privateIP
	add-certificate)
		generateCSR $@
		generateCertificate $@
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
		echo "Command not recognised. Use the `help` command to see what commands are available."
		;;
esac
