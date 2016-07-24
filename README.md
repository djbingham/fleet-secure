# Fleet CA
This project provides all that is required to run a Certificate Authority as a Docker container within a CoreOS fleet. The container may also be useful in other environments, but has not been tested as such.

###### Build, push and pull the container image
```
make build [tag=...]
make push [tag=...]
make pull [tag=...]
```

###### Generate a new certificate
```
make generate host=... privateIP=... publicIP=... [tag=...] [container=...]
```

e.g.
```
make generate host=core1 privateIP=127.0.0.1 publicIP=192.168.100.101
```

###### Start perpetual container for auto-renewal of certificates
```
make run [tag=...] [container=...]
```

###### Tail logs of the auto-renewal container
```
make logs
```

###### Stop and destroy auto-renewal container, including volumes
```
make run [container=...]
```

###### Run a command within a container with the same volumes and image as the auto-renewal container
```
make bash [tag=...] [cmd=...]
```
