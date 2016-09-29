#!/usr/bin/env bash
getOptions()
{
	echo 'Reading options:'
	while [ $# -gt 0 ]; do
		if [[ $1 == *'='* ]]; then
			option=${1%%=*}     # Extract name.
			value=${1##*=}         # Extract value.
			echo "${options}"$'\t'"${option} = ${value}"
			eval ${option}=${value}
		elif [[ ${task} == '' ]]; then
			task="$1"
		else
			arguments="$arguments $1"
		fi
		shift
	done
}

generateCA() {
	DIR_CA="${DIR_CERTIFICATES}/ca"
	FILE_CA_CSR="${DIR_CA}/csr.json"
	FILE_CA_KEY="${DIR_CERTIFICATES}/ca/ca-key.pem"
	FILE_CA_CERTIFICATE="${DIR_CERTIFICATES}/ca/ca.pem"

	echo " "
	echo "Generating Certificate Authority..."
	echo " "

	mkdir -p ${DIR_CA}
	cd ${DIR_CA}
	echo "Certificate Authority directory created. Generating CSR."

	generateCSR ca
	echo "Certificate Authority CSR generated. Generating Certificate."

	cfssl gencert -config ${FILE_CA_CONFIG} -initca ${FILE_CA_CSR} | cfssljson -bare ca -
	chmod 644 ${FILE_CA_KEY} ${FILE_CA_CERTIFICATE}
	echo " "
	echo "Certificate Authority generated."
	echo " "
}

generateCSR() {
	commonName="$1"
	hosts="$2"

	if [ "${commonName}" == "" ]; then
		echo "ERROR: A common name is required to generate a certificate signing request."
		exit
	fi

	targetDirectory="${DIR_CERTIFICATES}/${commonName}"
	request="${targetDirectory}/request.md"
	csr="${targetDirectory}/csr.json"

	echo "Generating certificate request.md and CSR..."

	mkdir -p ${targetDirectory}

	echo "
	commonName: ${commonName}
	hosts: ${hosts}
	" > ${request}
	echo "${request} created."
	cat ${request}

	commonNameRegex="s/\{\{commonName\}\}/${commonName}/"

	if [[ "${hosts}" == "" ]]; then
		hostsRegex="s/\{\{hosts\}\}//g"
	else
		escapedHosts="$(echo "${hosts}" | sed "s/[\.\s]/\\\&/g" | sed s/\,\ */\"\,\"/g)"
		hostsRegex="s/\{\{hosts\}\}/${escapedHosts}/g"
	fi

	cp ${FILE_CSR_TEMPLATE} ${csr}
	sed -i -E ${commonNameRegex} ${csr}
	sed -i -E ${hostsRegex} ${csr}
	echo "${csr} created."
}

generateCertificate() {
	commonName="$1"

	if [ "${commonName}" == "" ]; then
		echo "ERROR: Host required to generate a certificate."
		exit
	fi

	FILE_CA_CERTIFICATE="${DIR_CERTIFICATES}/ca/ca.pem"
	FILE_CA_KEY="${DIR_CERTIFICATES}/ca/ca-key.pem"

	targetDirectory="${DIR_CERTIFICATES}/${commonName}"
	request="${targetDirectory}/request.md"
	csr="${targetDirectory}/csr.json"
	certificate="${targetDirectory}/${commonName}.pem"
	privateKey="${targetDirectory}/${commonName}-key.pem"

	echo "Generating certificate..."

	cd ${targetDirectory}
	cfssl gencert -ca=${FILE_CA_CERTIFICATE} -ca-key=${FILE_CA_KEY} -config=${FILE_CA_CONFIG} ${csr} | cfssljson -bare ${commonName}
	chmod 644 ${FILE_CA_KEY} ${FILE_CA_CERTIFICATE}
	echo "Generated SSL certificate for commonName name ${commonName}, using the following CSR: "
	cat ${csr}
}

automate() {
	FREQUENCY=$1
	shift
	FUNCTION=$1
	shift

	echo " "
	echo ">>>> Automated execution of ${FUNCTION} (arguments: $@)."
	echo " "

	${FUNCTION} $@

	echo " "
	echo "<<<< Waiting ${FREQUENCY} seconds for next iteration of ${FUNCTION}."
	echo " "
	sleep ${FREQUENCY}
	automate ${FREQUENCY} ${FUNCTION} $@
}

renewAllCertificates() {
	CURRENT_TIME=$(date +%s)
	RENEWAL_THRESHOLD=$(expr ${CURRENT_TIME} + $(expr 7 \* 24 \* 60 \* 60 \* 300))

	# @todo Remove the following line. This is for testing only
	RENEWAL_THRESHOLD=$(expr ${CURRENT_TIME} + 15)

	echo "Checking all certificates for expiry before ${RENEWAL_THRESHOLD}."

	for folder in ${DIR_CERTIFICATES}/*; do
		if [ -d ${folder} ] && [ "${folder}" != "${DIR_CERTIFICATES}/ca" ]; then
			echo " "
			echo "Inspecting certificate in folder '${folder}'"

			certificateName=${folder##*/}
			request="${folder}/request.md"
			certificate="${folder}/${certificateName}.pem"

			echo "Certificate file: ${certificate}"
			echo "Certificate signing request:"
			cat ${folder}/csr.json

			expiryDate=$(date -d "$(openssl x509 -in ${certificate} | openssl x509 -noout -dates | grep notAfter | sed s/.*=//g)")
			expiryTime=$(date -d "${expiryDate}" +%s)

			echo "Certificate expires: ${expiryDate} (timestamp: ${expiryTime})."

			if [[ ${expiryTime} -le ${RENEWAL_THRESHOLD} ]]; then
				echo "Certificate requires renewal."

				echo "Generating certificate '${certificateName}'."
				generateCertificate ${certificateName}
			else
				echo "Certificate does not require renewal at this time."
			fi
		fi
	done

	echo " "
	echo "All certificates are now up to date."
}
