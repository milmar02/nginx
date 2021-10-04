FROM ubuntu:latest

COPY sources.list /etc/apt/sources.list
ADD https://github.com/krallin/tini/releases/download/v0.19.0/tini /tini

WORKDIR /app

RUN apt-get update && \
    apt-get install -y libfontconfig1 libpcre3 libpcre3-dev git dpkg-dev libpng-dev libssl-dev && \
    apt-get source nginx && \
    git clone https://github.com/chobits/ngx_http_proxy_connect_module && \
    cd /app/nginx-* && \
    patch -p1 < ../ngx_http_proxy_connect_module/patch/proxy_connect_rewrite_1018.patch && \
    cd /app/nginx-* && \
    ./configure --add-module=/app/ngx_http_proxy_connect_module --with-http_ssl_module \
      --with-http_stub_status_module --with-http_realip_module --with-threads && \
	./configure --prefix=/opt/nginx-1.17.8 --with-http_ssl_module && \
    make -j$(grep processor /proc/cpuinfo | wc -l) && \
    make install -j$(grep processor /proc/cpuinfo | wc -l) && \
    chmod +x /tini

#FROM $IMAGE

#LABEL maintainer='Robert Reiz <reiz@versioneye.com>'
RUN cd /app/nginx-*
COPY nginx_whitelist.conf /usr/local/nginx/conf/nginx.conf
COPY . /usr/local/nginx/sbin/nginx
#COPY --from=builder /tini /tini
## save apt-get update step
#COPY --from=builder /var/lib/apt/lists/ /var/lib/apt/lists/

RUN apt-get install -y --no-install-recommends libssl-dev && \
    mkdir -p /usr/local/nginx/logs/ && \
    touch /usr/local/nginx/logs/error.log && \
    apt-get clean autoclean && \
    apt-get autoremove --yes && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/

	RUN chgrp -R 0 /usr/local/nginx/ && \
	    chmod -R g+rwX /usr/local/nginx/

EXPOSE 8888

ENTRYPOINT ["/tini", "--"]

CMD ["/usr/local/nginx/sbin/nginx/nginx"]
