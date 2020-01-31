FROM ubuntu:18.04 as builder

# ARG ARCH_VARIANT=amd64
ARG ARCH_VARIANT=arm64

RUN apt-get update -y && apt-get install -y \
    autoconf \
    autoconf-archive \
    automake \
    autotools-dev \
    build-essential \
    g++  \
    gcc \
    git \
    libbz2-dev \
    libicu-dev \
    libsctp-dev \
    libtool \
    lksctp-tools \
    make \
    python-dev \
    pkg-config \
    software-properties-common \
    wget \
    zlib1g \
    zlib1g-dev \
    zlibc \
    zip



# RUN wget -q https://dl.yarnpkg.com/debian/pubkey.gpg -O - | apt-key add - \
#     && echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
#     && apt remove cmdtest \
#     && apt-get update -y && apt-get install -y yarn

# Install GO & dep
ENV GOLANG_VERSION=1.12.1
ENV GOLANG_PKG=go${GOLANG_VERSION}.linux-${ARCH_VARIANT}.tar.gz
ENV GOPATH=/go
ENV PATH="/usr/local/go/bin:${GOPATH}/bin:${PATH}"

RUN mkdir -p ${GOPATH}/bin
RUN wget -q https://dl.google.com/go/${GOLANG_PKG} \
    && tar xvzf ${GOLANG_PKG} -C /usr/local

RUN wget -q https://raw.githubusercontent.com/golang/dep/master/install.sh \
    && bash install.sh

ENV WORKDIR="$GOPATH/src/github.com/helm/chartmuseum"
RUN mkdir -p ${WORKDIR}
WORKDIR ${WORKDIR}

COPY . ${WORKDIR}/

RUN set -xv \
    && echo " ** WORKINGDIR: $(pwd)" && ls -la \
    && git submodule update --init --recursive \
    && make bootstrap

RUN make --debug=vjm build-linux


FROM alpine:3.8

#ARG ARCH=amd64
ARG ARCH=arm64

ENV BUILD_DIR=/go/src/github.com/helm/chartmuseum

RUN apk add --no-cache cifs-utils ca-certificates \
    && adduser -D -u 1000 chartmuseum
COPY --from=builder ${BUILD_DIR}/bin/linux/${ARCH}/chartmuseum /chartmuseum
USER 1000
ENTRYPOINT ["/chartmuseum"]
