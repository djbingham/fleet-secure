#!/usr/bin/env bash
initialiseCA() {
	DIR_CA="${DIR_CERTIFICATES}/ca"
	FILE_CA_CSR="${DIR_CA}/csr.json"

	echo ""
	echo "Generating Certificate Authority..."
	echo ""

	mkdir -p ${DIR_CA}
	cd ${DIR_CA}
	echo "Certificate Authority directory created. Generating CSR."

	createCSR ca
	echo "Certificate Authority CSR generated. Generating Certificate."

	cfssl gencert -config ${FILE_CA_CONFIG} -initca ${FILE_CA_CSR} | cfssljson -bare ca -
	echo ""
	echo "Certificate Authority generated."
	echo ""
}

createCSR() {
	hostName="$1"
	privateIP="$2"
	publicIP="$3"

	if [ "${hostName}" == "" ]; then
		echo "ERROR: Host required to generate a certificate signing request."
		exit
	fi

	targetDirectory="${DIR_CERTIFICATES}/${hostName}"
	request="${targetDirectory}/request.md"
	csr="${targetDirectory}/csr.json"

	echo "Generating certificate request.md and CSR..."

	mkdir -p ${targetDirectory}

	echo "
	host: ${hostName}
	privateIP: ${privateIP}
	publicIP: ${publicIP}
	" > ${request}
	echo "${request} created."
	cat ${request}

	cp ${FILE_CSR_TEMPLATE} ${csr}
	sed -i s/\{\{hostName\}\}/${hostName}/g ${csr}
	sed -i s/\{\{privateIP\}\}/${privateIP}/g ${csr}
	sed -i s/\{\{publicIP\}\}/${publicIP}/g ${csr}
	echo "${csr} created."
}

generateCertificate() {
	hostName="$1"

	if [ "${hostName}" == "" ]; then
		echo "ERROR: Host required to generate a certificate."
		exit
	fi

	FILE_CA_CERTIFICATE="${DIR_CERTIFICATES}/ca/ca.pem"
	FILE_CA_KEY="${DIR_CERTIFICATES}/ca/ca-key.pem"

	targetDirectory="${DIR_CERTIFICATES}/${hostName}"
	request="${targetDirectory}/request.md"
	csr="${targetDirectory}/csr.json"
	certificate="${targetDirectory}/${hostName}.pem"
	privateKey="${targetDirectory}/${hostName}-key.pem"

	echo "Generating certificate..."

	cd ${targetDirectory}
	cfssl gencert -ca=${FILE_CA_CERTIFICATE} -ca-key=${FILE_CA_KEY} -config=${FILE_CA_CONFIG} ${csr} | cfssljson -bare ${hostName}
	echo "Generated SSL certificate for host name ${hostName}, using the following CSR: "
	cat ${csr}
}

deployCertificate() {
	hostName="$1"
	publicIP="$2"

	if [ "${hostName}" == "" ]; then
		echo "ERROR: Host required to deploy a certificate."
		exit
	fi

	if [ "${publicIP}" == "" ]; then
		echo "ERROR: Host required to deploy a certificate."
		exit
	fi

	FILE_CA_CERTIFICATE="${DIR_CERTIFICATES}/ca/ca.pem"

	targetDirectory="${DIR_CERTIFICATES}/${hostName}"
	request="${targetDirectory}/request.md"
	certificate="${targetDirectory}/${hostName}.pem"
	privateKey="${targetDirectory}/${hostName}-key.pem"

	if [ "${publicIP}" == "" ]; then
		publicIP=$(cat ${request} | grep 'publicIP' | awk '{print $2}')

		if [[ "${publicIP}" == "" ]]; then
			echo "ERROR: The CSR for the requested host name does not contain a public IP. Cannot deploy without a public IP."
			exit
		fi
	fi

	destination="core@${publicIP}:"

	echo "Deploying certificate..."

	chmod 0644 ${privateKey}
	scp ${FILE_CA_CERTIFICATE} ${certificate} ${privateKey} ${destination}
	echo "Certificate files deployed to ${destination}.
	${certificate}
	${privateKey}
	"
}

automate() {
	FREQUENCY=$1
	shift
	FUNCTION=$1
	shift

	echo ""
	echo ">>>> Automated execution of ${FUNCTION} with arguments $@."
	echo ""

	${FUNCTION} $@

	echo ""
	echo "<<<< Waiting ${FREQUENCY} seconds for next iteration of ${FUNCTION}."
	echo ""
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
			echo ""
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

				publicIP=$(cat ${request} | grep 'publicIP' | awk '{print $2}')

				echo "Generating certificate '${certificateName}' and sending to public IP '${publicIP}'."
				generateCertificate ${certificateName}
				deployCertificate ${certificateName} ${publicIP}
			else
				echo "Certificate does not require renewal at this time."
			fi
		fi
	done

	echo ""
	echo "All certificates are now up to date."
}

generateFleetCertificates() {
	machines=$(fleetctl list-machines -fields=ip -no-legend)

	for ip in machines; do
		echo "Searching for existing CSR for machine ${ip}."

		# If CSR not found, generate one using `create CSR $host $privateIP $publicIP`
	done;
}