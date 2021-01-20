FROM openresty/openresty:bionic

RUN luarocks install lapis

WORKDIR /app
ADD . /app

ENTRYPOINT [ "lapis", "server" ]
