FROM ubuntu:22.04

# procps — для free и uptime, python3 — для HTTP-сервера
RUN apt-get update \
    && apt-get install -y --no-install-recommends procps python3 \
    && rm -rf /var/lib/apt/lists/*

ENV PYTHONUNBUFFERED=1

WORKDIR /var/www
COPY script.sh /usr/local/bin/script.sh
RUN chmod +x /usr/local/bin/script.sh

EXPOSE 8080

# скрипт пишет monitor.log в /var/www, http.server отдаёт этот каталог
CMD ["/bin/bash", "-c", "/usr/local/bin/script.sh & exec python3 -m http.server 8080"]
