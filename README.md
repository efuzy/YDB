## Run Binary 
Docker Hub has prebuilt Efuzy images. You must have at least docker 17.05.
Pull an image with binaries built from the latest source code:
```
docker pull efuzy/fuz:latest
```
### or Build 
```
docker build -t efuzy/fuz:latest .
```

## Run it
```
docker run -it -v /db:/data --network=host efuzy/fuz:latest
```
Note: You may need to use “sudo docker” in place of “docker” on some platforms depending on the permissions of the docker socket.


If you want to access the database from multiple containers (e.g., to add containers with a tool such as Kubernetes), they will need to share IPC resources and pids. So use a command such as:

```
docker run -it -v /db:/data --network=host --ipc=host --pid=host efuzy/fuz:latest
```