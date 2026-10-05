FROM debian:bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends vsftpd \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/run/vsftpd/empty /var/www/html

COPY conf/vsftpd.conf /etc/vsftpd.conf
COPY tools/ftp-entrypoint.sh /usr/local/bin/ftp-entrypoint.sh

RUN chmod +x /usr/local/bin/ftp-entrypoint.sh

EXPOSE 21 21100-21110

ENTRYPOINT ["/usr/local/bin/ftp-entrypoint.sh"]
CMD ["/usr/sbin/vsftpd", "/etc/vsftpd.conf"]
