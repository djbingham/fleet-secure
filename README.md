# Fleet Secure
**Work in Progress**

This project aims to provide a containerised certificate authority that automatically generates and renews certificates for a CoreOS fleet. It extends Cloudflare's cfssl container, using cfssl commands to generate and inspect certificates.

Currently a CA certificate and initial client-server certificate for Fleet must be generated in advance and pasted into the cloud config in order for Fleet to be able to start the systemd units. The can probably be overcome by starting the server in non-TLS mode so that Fleet can startup the required units to generate a CA and certificates before enabling TLS. This whole process can hopefully be automated through a one-shot systemd unit defined in the cloud config.

## Usage

### Systemd Units
```
fleetctl submit units/*
fleetctl start fleet-ca
```

The recommended usage of this project is via Fleet. The `units` folder contains service files defining systemd units that will initialise a certificate authority per machine in the Fleet cluster, then generate a certificate per machine, configured to allow communication on each machine's private IP address only. The certificates will then be checked at regular intervals for upcoming expiry and renewed automatically prior to expiry.

The commands above need only be run once, on any machine in your cluster, to initialise the CA and certificates throughout. The status and logs of started units can be checked via:
```
fleetctl list-units
journalctl -efu fleet-ca
```
*In the `journalctl` command above, the arguments are as follows:*
```
-e:          Jump to end of log
-f:          Follow the log
-u fleet-ca: Show logs from the fleet-ca unit only
```

### task.sh
```
./task.sh [task] [options]
```

A utility script, `task.sh` is provided for direct execution of tasks against Docker containers without the use of Fleet. A plain bash script is used (as opposed to a Makefile, for instance) because CoreOS does not come with Make installed and does not allow for such tools to be easily installed outside of a container.

To see what commands are available, clone this repository and run `./task.sh help`.

### test.sh
```
./test.sh [task] [options]
```

For testing changes to this project, there is also a `test.sh` script, which will ensure that project files are mounted from the host machine, rather than using the files built into the Docker container image. This enables changes to the project to be tested without re-building the container.

Executing the test script as above is equivalent to the following:
```
ENVIRONMENT=development ./task.sh [task] [options]
```

## Testing security certificates
curl --key /home/core/certificates/fleet/coreos-key.pem --cert /home/core/certificates/fleet/coreos.pem --cacert /home/core/certificates/fleet/ca.pem -L https://127.0.0.1:2379/v2/keys/foo -XPUT -d value=bar -v

