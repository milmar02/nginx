#@# vim: set filetype=dockerfile:
FROM alpine:latest

ENV NGINX_VERSION 1.17.5

####
## dependent packages for docker build
####

WORKDIR /tmp
RUN chgrp -R 0 /tmp/ && \
    chmod -R g+rwX /tmp/

RUN apk update && \
    apk add       \
      alpine-sdk  \
      openssl-dev \
      pcre-dev    \
      zlib-dev    \
      curl

RUN curl -LSs http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -O                                             && \
    tar xf nginx-${NGINX_VERSION}.tar.gz                                                                             && \
    cd     nginx-${NGINX_VERSION}                                                                                    && \
    git clone https://github.com/chobits/ngx_http_proxy_connect_module                                               && \
    patch -p1 < ./ngx_http_proxy_connect_module/patch/proxy_connect_rewrite_101504.patch                             && \
    ./configure                                                                                                         \
      --add-module=./ngx_http_proxy_connect_module                                                                      \
      --sbin-path=/usr/sbin/nginx                                                                                       \
      --with-cc-opt='-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fPIC' && \
    make -j $(nproc)                                                                                                 && \
    make install                                                                                                     && \
    rm -rf /tmp/*

####
## application deployment
####

WORKDIR /

RUN chgrp -R 0 /usr/local/nginx/ && \
    chmod -R g+rwX /usr/local/nginx/

COPY ./nginx.conf /usr/local/nginx/conf/nginx.conf

EXPOSE 3128

STOPSIGNAL SIGTERM

CMD [ "nginx", "-g", "daemon off;" ]
