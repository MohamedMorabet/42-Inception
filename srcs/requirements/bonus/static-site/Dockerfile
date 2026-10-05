FROM debian:bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends nginx \
    && rm -rf /var/lib/apt/lists/*

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY html/ /var/www/portfolio/

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
