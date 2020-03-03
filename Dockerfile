FROM ubuntu:bionic-20190612

ENV SQUID_VERSION=3.5.27

WORKDIR /root

RUN sed -i -r "s/^# (deb-src .* bionic main restricted)$/\1/" /etc/apt/sources.list \
  && apt-get update \
  && apt-get install -y dpkg-dev \
  && chown -Rv _apt:root /var/cache/apt/archives/partial \
  && chmod -Rv 700 /var/cache/apt/archives/partial \
  && apt-get source squid \
  && apt-get build-dep -y squid \
  && apt-get -y install devscripts build-essential fakeroot libssl1.0-dev \
  && cd squid3-${SQUID_VERSION} \
  && sed -i -e '46a \                --enable-ssl-crtd \\' debian/rules \
  && sed -i -e '46a \                --with-openssl \\' debian/rules \
  && ./configure \
  && debuild -us -uc -b

FROM ubuntu:bionic-20190612

ENV SQUID_VERSION=3.5.27 \
    SQUID_CACHE_DIR=/var/spool/squid \
    SQUID_LOG_DIR=/var/log/squid \
    SQUID_USER=proxy

WORKDIR /root

COPY --from=0 /root/squid*.deb /root/

RUN apt-get update \
  && rm squid-cgi_3.5.27-1ubuntu1_amd64.deb \
  && apt-get install -y libssl1.0-dev squid \
  && dpkg -i ./squid*.deb \
  && /usr/lib/squid/ssl_crtd -c -s /var/lib/ssl_db

COPY entrypoint.sh /sbin/entrypoint.sh

EXPOSE 3128/tcp
ENTRYPOINT ["/sbin/entrypoint.sh"]
