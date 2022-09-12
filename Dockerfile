ARG ALPINE_VERSION

FROM golang:alpine AS builder
LABEL maintainer="Sergio Talens-Oliag <sto@kyso.io>"
WORKDIR /go/src/github.com/adnanh/webhook
RUN apk update &&\
 apk add --no-cache -t build-deps curl libc-dev gcc libgcc patch &&\
 curl -L --silent -o webhook.tar.gz\
 https://github.com/adnanh/webhook/archive/2.8.0.tar.gz &&\
 tar -xzf webhook.tar.gz --strip 1 &&\
 curl -L --silent -o 549.patch\
 https://patch-diff.githubusercontent.com/raw/adnanh/webhook/pull/549.patch &&\
 patch -p1 < 549.patch &&\
 go get -d && \
 go build -o /usr/local/bin/webhook

FROM alpine:$ALPINE_VERSION
LABEL maintainer="Sergio Talens-Oliag <sto@kyso.io>"
RUN apk update &&\
 apk add --no-cache mailcap nodejs npm util-linux-misc &&\
 apk add --no-cache s3fs-fuse \
   --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/ &&\
 rm -rf /var/cache/apk/* &&\
 npm install --location=global kyso
COPY --from=builder /usr/local/bin/webhook /usr/local/bin/webhook
COPY entrypoint.sh /
COPY hooks/* /webhook/hooks/
EXPOSE 9000
ENTRYPOINT ["/entrypoint.sh"]
CMD ["server"]
