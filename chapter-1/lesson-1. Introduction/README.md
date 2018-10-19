### Отчет по домашней работе
[Инструкция по сборке ядра][1]

Скачал.
Создал директорию /root/kernel_sources/

Долго искал конфиг ядра текущий.
Где его нет:
```bash
/boot/
/proc/config.gz - пусто
/lib/modules/3.10.0-693.el7.x86_64/build/
/usr/src/kernels/3.10.0-862.14.4.el7.x86_64/lib/Kconfig
```
Тут наконец нашел:
```bash
/usr/src/kernels/3.10.0-862.14.4.el7.x86_64/.config
```
Сразу покажу где ошибку сделал.
```
cp /usr/src/kernels/3.10.0-862.14.4.el7.x86_64/.config /root/kernel_sources/.config
```
Так ошибка очевиднее. Директория куда все накопировал и распаковал.
```bash
[root@localhost kernel_sources]# ls -la
total 99580
drwxr-xr-x.  3 root root        70 Oct 17 22:20 .
dr-xr-x---.  8 root root       261 Oct 15 11:06 ..
-rw-r--r--.  1 root root    147859 Oct 17 22:20 .config
drwxrwxr-x. 25 root root      4096 Oct 17 22:05 linux-4.18.12
-rw-r--r--.  1 root root 101812028 Oct  3 17:06 linux-4.18.12.tar.xz
```

```
[root@localhost kernel_sources]# make oldconfig
make: *** No rule to make target `oldconfig'.  Stop.
```
Вот что мне ругается. Форумы писали, запускать make нужно там где есть Makefile. Но кто будет вчитываться? Пробежал, очевидный вариант команды - "жми так и будет все хорошо" - не нашел и тупил.

Директория не та была.
```
cp .config linux-4.18.12/.config
```

Очередные попытки заканчивались неудачей по причине отсутствия пакетов.
```
[root@localhost linux-4.18.12]# make oldconfig
  YACC    scripts/kconfig/zconf.tab.c
/bin/sh: bison: command not found
make[1]: *** [scripts/kconfig/zconf.tab.c] Error 127
make: *** [oldconfig] Error 2
```
при запуске он будет ругаться на отсутствие пакетов. 
Например - bison.  [ Еще такая ошибка была ][2] - тоже спасли пакеты.
Полный список в соседних файлах.

---

[1]: https://losst.ru/sobiraem-yadro-linux
[2]: https://stackoverflow.com/questions/46008624/how-to-fix-fatal-error-openssl-opensslv-h-no-such-file-or-directory-in-redhat