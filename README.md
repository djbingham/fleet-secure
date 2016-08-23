# Fleet CA
This is a work in progress aiming to provide a containerised certificate authority that automatically generates and renews certificates for a CoreOS fleet. Commands should be executed via `task.sh`. The reason for using a plain bash script as opposed to, for example, a Makefile is that CoreOS does not come with Make installed and does not allow such tools to be easily installed outside of a container.

To see what commands are available, clone this repository and run `. task.sh help`.

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

###### Generate a new certificate
```
. task.sh add-certificate host=... privateIP=... publicIP=... [tag=...] [container=...]
```

e.g.
```
. task.sh add-certificate host=core1 privateIP=127.0.0.1 publicIP=192.168.100.101
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
