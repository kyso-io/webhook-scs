ARG ALPINE_VERSION
FROM registry.kyso.io/docker/alpine:$ALPINE_VERSION
LABEL maintainer="Sergio Talens-Oliag <sto@kyso.io>"
RUN apk update &&\
 apk add --no-cache util-linux-misc webhook &&\
 rm -rf /var/cache/apk/*
COPY entrypoint.sh /
COPY hooks/* /webhook/hooks/
EXPOSE 9000
ENTRYPOINT ["/entrypoint.sh"]
CMD ["server"]
