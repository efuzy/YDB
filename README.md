# Running fuz container
## Run Binary 
Docker Hub has prebuilt Efuzy images. You must have at least docker 17.05.
Pull an image with binaries built from the latest source code:
```
docker pull efuzy/fuz:latest
```
## Or Build One
```
docker build -t efuzy/fuz:latest .
```
## Then Run it
```
docker run -it -v /db:/data --network=host -e ydb_chset=utf-8  --restart unless-stopped --name=fuz efuzy/fuz:latest
```

```
- it       => interactive
- v        =>  map the folder /db on the host to folder /data in the container, where the actual db         is stored, along with the routine source, and generated object code
--name     => name the container
--network  => basically socket is attached straight to the process as if there is no                      container overhead 
- e        => set ydb_chset environment variable
```


Note: You may need to use “sudo docker” in place of “docker” on some platforms depending on the permissions of the docker socket.


If you want to access the database from multiple containers (e.g., to add containers with a tool such as Kubernetes), they will need to share IPC resources and pids. So use a command such as 

```

--ipc host 
--pid host 

```
https://docs.docker.com/engine/reference/run/#ipc-settings---ipc

--ipc=host removes a layer of security and creates new attack vectors as any application running on the host that misbehaves when presented with malicious data in shared memory segments can become a potential attack vector but as long as your image of the container is from a reliable source it shouldn't affect your host.

Performance-sensitive programs use shared memory to store and exchange volatile data (x11 frame buffers are one example). In your case the non-root user in the container has access to the x11 server shared memory.

Running as non-root inside the container should somewhat limit unauthorized access, assuming correct permissions are set on all shared objects. Nonetheless if an attacker gained root privileges inside your container they would have access to all shared objects owned by root (some objects might still be restricted by the IPC_OWNER capability which is not enabled by default).
