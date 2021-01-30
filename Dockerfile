FROM openresty/openresty:bionic

RUN apt-get update && apt-get install -y \
  libssl-dev

RUN luarocks install lapis

WORKDIR /app
ADD . /app

USER nobody

ENTRYPOINT [ "lapis" ]
CMD [ "server" ]
