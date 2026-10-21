FROM ubuntu:22.04

# free и uptime входят в пакет procps, которого нет в базовом образе
RUN apt-get update \
    && apt-get install -y --no-install-recommends procps \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www
COPY script.sh /usr/local/bin/script.sh
RUN chmod +x /usr/local/bin/script.sh

CMD ["/usr/local/bin/script.sh"]
