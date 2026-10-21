# my-sysadmin-scripts

`script.sh` раз в 10 секунд дописывает в `monitor.log` снимок `free -h`, `df -h` и `uptime` с временной меткой.

```bash
./script.sh                     # бесконечно, остановка по Ctrl+C
MAX_ITERATIONS=3 ./script.sh    # 3 снимка и выход
```

Пример вывода — в [sample_output.txt](sample_output.txt).
