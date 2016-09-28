# Fleet CA
This is a work in progress aiming to provide a containerised certificate authority that automatically generates and renews certificates for a CoreOS fleet. Commands should be executed via `task.sh`. The reason for using a plain bash script as opposed to, for example, a Makefile is that CoreOS does not come with Make installed and does not allow such tools to be easily installed outside of a container.

To see what commands are available, clone this repository and run `./task.sh help`.

## Testing in development
To test any changes to this project, simply set the environment variable `ENVIRONMENT=development`, before running any tasks as normal. For extra convenience, an additional script is included that will take care of this for you:
```
./test.sh [task] [options]
```
Executing the above is completely equivalent to:
```
ENVIRONMENT=development ./task.sh [task] [options]
```

## Common Tasks

### Container Management

###### Build, push and pull the container image
```
. task.sh build [tag=...]
. task.sh push [tag=...]
. task.sh pull [tag=...]
```

###### Start perpetual container for auto-renewal of certificates
```
. task.sh run [tag=...] [container=...] [certificateVolume=...]
```

When working on this project it is useful to run the container with host-mounted scripts and configuration files, so that changes are reflected immediately without needing to rebuild the container:

```
. task.sh test [tag=...] [container=...] [certificateVolume=...]
```

###### Stop and destroy the auto-renewal container, including volumes
```
. task.sh stop [contianer=...]
. task.sh destroy [container=...]
```

### Using the running container

###### Generate a new certificate authority
```
. task.sh generate-ca [tag=...] [container=...]
```

e.g.
```
. task.sh generate-ca
```

###### Generate a new certificate
```
. task.sh generate-certificate commonName=... hosts=... [tag=...] [container=...]
```

The `hosts` value should be a comma-separated list of host names and IP addresses for which the certificate will be valid. e.g.
```
. task.sh generate-certificate commonName=fleet hosts="192.168.100.101, 192.168.100.102, 192.168.100.103"
```

###### Tail the logs
```
. task.sh logs
```

###### Execute a command within the running container
```
. task.sh exec [tag=...] [command=...]
```

### Working with the certificate volume

###### Execute a command within a separate container that shares volumes and image with the running container
```
. task.sh execute [tag=...] [entrypoint=...] [command=...]
```

## Testing security certificates
curl --key /home/core/certificates/fleet/coreos-key.pem --cert /home/core/certificates/fleet/coreos.pem --cacert /home/core/certificates/fleet/ca.pem -L https://127.0.0.1:2379/v2/keys/foo -XPUT -d value=bar -v

