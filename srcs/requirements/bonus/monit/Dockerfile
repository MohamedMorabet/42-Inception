FROM debian:bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends monit \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/lib/monit

COPY conf/monitrc /etc/monit/monitrc.template
COPY tools/monit-entrypoint.sh /usr/local/bin/monit-entrypoint.sh

RUN chmod +x /usr/local/bin/monit-entrypoint.sh

EXPOSE 2812

ENTRYPOINT ["/usr/local/bin/monit-entrypoint.sh"]
CMD ["monit", "-I", "-c", "/etc/monit/monitrc"]
