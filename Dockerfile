ARG ALPINE_VERSION
FROM alpine:$ALPINE_VERSION
LABEL maintainer="Sergio Talens-Oliag <sto@kyso.io>"
RUN apk update &&\
 apk add --no-cache mailcap util-linux-misc webhook &&\
 apk add --no-cache s3fs-fuse \
   --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/ &&\
 rm -rf /var/cache/apk/*
COPY entrypoint.sh /
COPY hooks/* /webhook/hooks/
EXPOSE 9000
ENTRYPOINT ["/entrypoint.sh"]
CMD ["server"]
