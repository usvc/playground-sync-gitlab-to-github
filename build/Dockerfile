FROM alpine:latest AS build
RUN apk update --no-cache
RUN apk upgrade --no-cache
WORKDIR /
RUN echo '#!/bin/sh' > /entrypoint
RUN echo 'printf -- "hello world"' > /entrypoint
ENTRYPOINT [ "/entrypoint" ]
