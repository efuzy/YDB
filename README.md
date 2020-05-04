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
docker run -it -v /db:/data --network=host -e ydb_chset=utf-8 --name=fuz efuzy/fuz:latest
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


# PERFORMANCE
## inside the container
```
 apt install apt-file  && apt-file update && apt-get install -y libcap2-bin
 setcap 'cap_ipc_lock+ep' /opt/yottadb/current/ydb
 wget https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/libhugetlbfs/2.22-1/libhugetlbfs_2.22.orig.tar.gz
 tar -xvf libhugetlbfs_2.22.orig.tar.gz
 make
 make check
 make install
 make install PREFIX=/usr/local.

 echo gid >/proc/sys/vm/hugetlb_shm_group
 
 Set the environment variable HUGETLB_SHM for each process to “yes”.
 
To use huge pages for process working space and dynamically linked code:
Set the environment variable HUGETLB_MORECORE for each process to “yes”.

Although not required to use huge pages, your application is also likely to benefit from including the path to libhugetlbfs.so in the LD_PRELOAD environment variable.

If you enable huge pages for all applications (by setting HUGETLB_MORECORE, HUGETLB_SHM, and LD_PRELOAD as discussed above in /etc/profile and/or /etc/csh.login), you may find it convenient to suppress warning messages from common applications that are not configured to take advantage of huge pages by also setting the environment variable HUGETLB_VERBOSE to zero (0).
```

https://linux.die.net/man/7/capabilities
Configuring huge pages for YottaDB on Linux
Huge pages are a Linux feature that may improve the performance of YottaDB applications in production. Huge pages create a single page table entry for a large block (typically 2MiB) of memory in place of hundreds of entries for many smaller (typically 4KiB) blocks. This reduction of memory used for page tables frees up memory for other uses, such as file system caches, and increases the probability of TLB (translation lookaside buffer) matches - both of which can improve performance. The performance improvement related to reducing the page table size becomes evident when many processes share memory as they do for global buffers, journal buffers, and replication journal pools. Configuring huge pages on Linux for x86 or x86_64 CPU architectures help improve:

YottaDB shared memory performance: When your YottaDB database uses journaling, replication, and the BG access method.

YottaDB process memory performance: For your process working space and dynamically linked code.

Note

At this time, huge pages have no effect for MM databases; the text, data, or bss segments for each process; or for process stack.

While YottaDB recommends you configure huge pages for shared memory, you need to evaluate whether or not configuring huge pages for process-private memory is appropriate for your application. Having insufficient huge pages available during certain commands (for example, a JOB command - see complete list below) can result in a process terminating with a SIGBUS error. This is a current limitation of Linux. Before you use huge pages for process-private memory on production systems, YottaDB recommends that you perform appropriate peak load tests on your application and ensure that you have an adequate number of huge pages configured for your peak workloads or that your application is configured to perform robustly when processes terminate with SIGBUS errors.

The following YottaDB features fork processes and may generate SIGBUS errors when huge pages are not available - JOB, OPEN a PIPE device, ZSYSTEM, interprocess signaling that requires the services of gtmsecshr when gtmsecshr is not already running, SPAWN commands in DSE, GDE, and LKE, argumentless MUPIP RUNDOWN, and replication-related MUPIP commands that start server processes and/or helper processes. As increasing the available huge pages may require a reboot, an interim workaround is to unset the environment variable HUGETLB_MORECORE for YottaDB processes until you are able to reboot or otherwise make available an adequate supply of huge pages.

Consider the following example of a memory map report of a Source Server process running at peak load:

$ pmap -d 18839
18839: /usr/lib/yottadb/r120/mupip replicate -source -start -buffsize=1048576 -secondary=melbourne:1235 -log=/var/log/.yottadb/mal2mel.log -instsecondary=melbourne
Address   Kbytes Mode Offset   Device Mapping
--- lines removed for brevity -----
mapped: 61604K writeable/private: 3592K shared: 33532K
$
Process id 18839 uses a large amount of shared memory (33535K) and can benefit from configuring huge pages for shared memory. Configuring huge pages for shared memory does not cause a SIGBUS error when a process does a fork. For information on configuring huge pages for shared memory, refer to the “Using huge pages” and “Using huge pages for shared memory” sections. SIGBUS errors only occur when you configure huge pages for process-private memory; these errors indicate you have not configured your system with an adequate number of huge pages. To prevent SIGBUS errors, you should perform peak load tests on your application to determine the number of required huge pages. For information on configuring huge pages for process-private memory, refer to the “Using huge pages” and “Using huge pages for process working space” sections.

As application response time can be adversely affected if processes and database shared memory segments are paged out, YottaDB recommends configuring systems for use in production with sufficient RAM so as to not require swap space or a swap file. While you must configure an adequate number of huge pages for your application needs as empirically determined by benchmarking/testing and there is little downside to a generous configuration to ensure a buffer of huge pages available for workload spikes, an excessive allocation of huge pages may affect system throughput by reserving memory for huge pages that could otherwise be used by applications that cannot use huge pages.

Using huge pages
Prerequisites

Notes

A 32- or 64-bit x86 CPU running a Linux kernel with huge pages enabled

All currently Supported Linux distributions appear to support huge pages; to confirm, use the command: grep hugetlbfs /proc/filesystems which should report: nodev hugetlbfs

libhugetlbfs.so

Use your Linux system’s package manager to install the libhugetlbfs.so library in a standard location. Note that libhugetlbfs is not in Debian repositories and must be manually installed; YottaDB on Debian releases is Supportable, not Supported.

Have sufficient number of huge pages available.

To reserve Huge Pages boot Linux with the hugepages=num_pages kernel boot parameter; or, shortly after bootup when unfragmented memory is still available, with the command: hugeadm –pool-pages-min DEFAULT:num_pages For subsequent on-demand allocation of Huge Pages, use: hugeadm –pool-pages-max DEFAULT:num_pages These delayed (from boot) actions do not guarantee availability of the requested number of huge pages; however, they are safe as, if a sufficient number of huge pages are not available, Linux simply uses traditional sized pages.

Using Huge Pages for Shared Memory

To use huge pages for shared memory (journal buffers, replication journal pool and global buffers):

Permit YottaDB processes to use huge pages for shared memory segments (where available, YottaDB recommends option 1 below; however not all file systems support extended attributes). Either:

Set the CAP_IPC_LOCK capability needs for your yottadb, mupip and dse processes with a command such as:

setcap 'cap_ipc_lock+ep' $ydb_dist/yottadb
.

Permit the group used by YottaDB processes to use huge pages with the following command, which requires root privileges:

echo gid >/proc/sys/vm/hugetlb_shm_group
Set the environment variable HUGETLB_SHM for each process to “yes”.

Using huge pages for YottaDB process working space

To use huge pages for process working space and dynamically linked code:

Set the environment variable HUGETLB_MORECORE for each process to “yes”.

Although not required to use huge pages, your application is also likely to benefit from including the path to libhugetlbfs.so in the LD_PRELOAD environment variable.

If you enable huge pages for all applications (by setting HUGETLB_MORECORE, HUGETLB_SHM, and LD_PRELOAD as discussed above in /etc/profile and/or /etc/csh.login), you may find it convenient to suppress warning messages from common applications that are not configured to take advantage of huge pages by also setting the environment variable HUGETLB_VERBOSE to zero (0).

Refer to the documentation of your Linux distribution for details. Other sources of information are:

http://www.kernel.org/doc/Documentation/vm/hugetlbpage.txt

http://lwn.net/Articles/374424/

https://www.ibm.com/developerworks/community/blogs/fe313521-2e95-46f2-817d-44a4f27eba32/entry/backing_guests_with_hugepages?lang=en

the HOWTO guide that comes with libhugetlbfs (http://sourceforge.net/projects/libhugetlbfs/files/)

Note

Since the memory allocated by Linux for shared memory segments mapped with huge pages is rounded up to the next multiple of huge pages, there is potentially unused memory in each such shared memory segment. You can therefore increase any or all of the number of global buffers, journal buffers, and lock space to make use of this otherwise unused space. You can make this determination by looking at the size of shared memory segments using ipcs. Contact YottaDB support for a sample program to help you automate the estimate. Transparent huge pages may further improve virtual memory page table efficiency. Some supported releases automatically set transparent_hugepages to “always”; others may require it to be set at or shortly after boot-up. Consult your Linux distribution’s documentation.