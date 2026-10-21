# my-sysadmin-scripts

`script.sh` раз в 10 секунд дописывает в `monitor.log` снимок `free -h`, `df -h` и `uptime` с временной меткой.

```bash
./script.sh                     # бесконечно, остановка по Ctrl+C
MAX_ITERATIONS=3 ./script.sh    # 3 снимка и выход
```

Пример вывода — в [sample_output.txt](sample_output.txt).

## Docker

Образ запускает скрипт в фоне и отдаёт его рабочий каталог (`monitor.log`) по HTTP на порту 8080.

```bash
docker build -t my-script .
docker run -d --init -p 127.0.0.1:8080:8080 --name my-app \
  -v /etc/localtime:/etc/localtime:ro my-script
curl http://127.0.0.1:8080/monitor.log
```

`docker compose up` — разовый прогон только скрипта: два снимка в вывод контейнера и выход.

## Развёртывание

| Файл | Куда | Что делает |
|---|---|---|
| [deploy/nginx/my-app.conf](deploy/nginx/my-app.conf) | `/etc/nginx/sites-available/my-app` | reverse proxy на 127.0.0.1:8080, TLS, редирект 80 → 443 |
| [deploy/systemd/my-app.service](deploy/systemd/my-app.service) | `/etc/systemd/system/my-app.service` | автозапуск контейнера `my-app` после Docker |
| [deploy/storage/storage-up.sh](deploy/storage/storage-up.sh) | `/usr/local/sbin/storage-up.sh` | после ребута заново подключает loop-устройства, собирает RAID 1, активирует LVM и монтирует `/mnt/raid`, `/mnt/logs` |
| [deploy/systemd/storage-up.service](deploy/systemd/storage-up.service) | `/etc/systemd/system/storage-up.service` | запускает `storage-up.sh` при загрузке |

Сертификат самоподписанный:

```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/my-app.key -out /etc/ssl/certs/my-app.crt \
  -subj "/CN=my-app.local"
```

Проверка: `curl -kI https://<адрес-машины>/monitor.log` → `HTTP/2 200`.
