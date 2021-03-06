ARG OS_VSN=18.04
FROM ubuntu:${OS_VSN}
ARG CMAKE_BUILD_TYPE=Release
ARG DEBIAN_FRONTEND=noninteractive
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
                    && \
                    apt-get install -y \
                    binutils \
                    locales \
                    wget \
                    vim \
                    g++ \ 
                    libssl-dev \
                    apache2-utils \
                    curl \
                    git \
                    python \
                    make \
                    nano \
                    apt-utils --no-install-recommends
RUN                 mkdir /usr/local/node && cd $_ && \
                    wget -qO- http://nodejs.org/dist/node-latest.tar.gz | tar xz --strip-components=1 && \
                    ./configure --prefix=/usr/local && \
                    make install && \ 
                    wget -qO- https://www.npmjs.org/install.sh | sh && \
                    apt-get clean && \
                   rm -rf /var/lib/apt/lists/*
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
 && make install 

RUN locale-gen en_US.UTF-8
WORKDIR /data
RUN  cd /tmp/yottadb-release  \
   && pkg-config --modversion icu-io \
      > /tmp/yottadb-release/.icu.vsn \
 && ./ydbinstall \
      --utf8 `cat /tmp/yottadb-release/.icu.vsn` \
      --installdir /opt/yottadb/current \
 && rm -rf /tmp/yottadb-release
ENV gtmdir=/data \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8
ENTRYPOINT ["/opt/yottadb/current/ydb"] 