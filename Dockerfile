FROM scratch
ARG OS_VSN=18.04
ARG CMAKE_BUILD_TYPE=Release
RUN apt-get update && \
    apt-get install -y \
                    file \
                    cmake \
                    tcsh \
                    libconfig-dev \
                    libelf-dev \
                    libgcrypt-dev \
                    libgpg-error-dev \
                    libgpgme11-dev \
                    libicu-dev \
                    libncurses-dev \
                    libssl-dev \
                    zlib1g-dev \
                    binutils \
                    locales \
                    wget \
                    vim \
                    apt-get install -yq g++ apache2-utils curl git python make nano \
                    locale-gen en_US.UTF-8 \
                    apt install apt-file -y \
                    apt-file update && \
                    apt-get install -y libcap2-bin \
                    setcap 'cap_ipc_lock+ep' /opt/yottadb/current/ydb \
                    apt-get clean \ 
                    apt-file clean

ADD . /tmp/yottadb-src

RUN mkdir -p /tmp/yottadb-build \
    && cd /tmp/yottadb-build \
   && test -f /tmp/yottadb-src/.yottadb.vsn || \
    grep YDB_ZYRELEASE /tmp/yottadb-src/sr_*/release_name.h \
    | grep -o '\(r[0-9.]*\)' \
    | sort -u \
    > /tmp/yottadb-src/.yottadb.vsn \
    && cmake \
      -D CMAKE_INSTALL_PREFIX:PATH=/tmp \
      -D YDB_INSTALL_DIR:STRING=yottadb-release \
      -D CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
      /tmp/yottadb-src \
      && make -j $(nproc) \
      && make install  \
      mkdir /usr/local/node && cd $_ && \
     wget -qO- http://nodejs.org/dist/node-latest.tar.gz | tar xz --strip-components=1 && \
     ./configure --prefix=/usr/local && \
     make install && \ 
     wget -qO- https://www.npmjs.org/install.sh | sh \
     &&  npm install -g @quasar/cli \
     && apt install apt-file -y && \
     apt-file update && \
     apt-get install -y libcap2-bin && \
  setcap 'cap_ipc_lock+ep' /opt/yottadb/current/ydb
  
WORKDIR /data

COPY --from=ydb-release-builder /tmp/yottadb-release /tmp/yottadb-release

RUN cd /tmp/yottadb-release  \
 && pkg-config --modversion icu-io \
      > /tmp/yottadb-release/.icu.vsn \
 && ./ydbinstall \
      --utf8 `cat /tmp/yottadb-release/.icu.vsn` \
      --installdir /opt/yottadb/current \
      --force-install \
 && rm -rf /tmp/yottadb-release \
 && echo gid >/proc/sys/vm/hugetlb_shm_group

ENV gtmdir=/data \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    HUGETLB_SHM=yes \
    HUGETLB_MORECORE=yes \
    LD_PRELOAD=libhugetlbfs.so \
    HUGETLB_VERBOSE=0 

ENTRYPOINT ["/opt/yottadb/current/ydb"]
