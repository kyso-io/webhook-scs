ARG ALPINE_VERSION

FROM registry.kyso.io/docker/golang:alpine$ALPINE_VERSION AS builder
LABEL maintainer="Sergio Talens-Oliag <sto@kyso.io>"
ENV WEBHOOK_VERSION 2.8.0
ENV WEBHOOK_PR 549
ENV S3FS_VERSION v1.91
WORKDIR /go/src/github.com/adnanh/webhook
RUN apk update &&\
 apk add --no-cache -t build-deps curl libc-dev gcc libgcc patch
RUN curl -L --silent -o webhook.tar.gz\
 https://github.com/adnanh/webhook/archive/${WEBHOOK_VERSION}.tar.gz &&\
 tar xzf webhook.tar.gz --strip 1 &&\
 curl -L --silent -o ${WEBHOOK_PR}.patch\
 https://patch-diff.githubusercontent.com/raw/adnanh/webhook/pull/${WEBHOOK_PR}.patch &&\
 patch -p1 < ${WEBHOOK_PR}.patch &&\
 go get -d && \
 go build -o /usr/local/bin/webhook
WORKDIR /src/s3fs-fuse
RUN apk update &&\
 apk add ca-certificates build-base alpine-sdk libcurl automake autoconf\
 libxml2-dev libressl-dev mailcap fuse-dev curl-dev
RUN curl -L --silent -o s3fs.tar.gz\
 https://github.com/s3fs-fuse/s3fs-fuse/archive/refs/tags/$S3FS_VERSION.tar.gz &&\
 tar xzf s3fs.tar.gz --strip 1 &&\
 ./autogen.sh &&\
 ./configure --prefix=/usr/local &&\
 make -j && \
 make install

FROM registry.kyso.io/docker/alpine:$ALPINE_VERSION
LABEL maintainer="Sergio Talens-Oliag <sto@kyso.io>"
WORKDIR /webhook
RUN apk update &&\
 apk add --no-cache ca-certificates mailcap fuse libxml2 libcurl libgcc\
 libstdc++ rsync nodejs npm util-linux-misc &&\
 npm install -g kyso &&\
 rm -rf /var/cache/apk/*
COPY --from=builder /usr/local/bin/webhook /usr/local/bin/webhook
COPY --from=builder /usr/local/bin/s3fs /usr/local/bin/s3fs
COPY entrypoint.sh /
COPY hooks/* ./hooks/
EXPOSE 9000
ENTRYPOINT ["/entrypoint.sh"]
CMD ["server"]
