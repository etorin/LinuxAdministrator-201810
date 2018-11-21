### Systemd

#### Задание 1
Проверить, с чем имеем дело
```bash
readlink /proc/1/exe
```
```
/sbin/init
или
/lib/systemd/systemd 
```


Написать сервис, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова. Файл и слово должны задаваться в /etc/sysconfig

Вот тут что-то есть по данной теме.
https://codebeer.ru/dobavit-servis-v-systemd/ 
Подробно про юнит файл
http://linux-notes.org/pishem-systemd-unit-fajl/

`[Unit]`
`Description=` Описание
`After=` Порядок загрузки. Тут не очевидно, куда нужно его расположить, если нам не принципиально. Буду наедяться, `network.target` сойдет

`[Service]` 
`Type=simple` Используется по умолчанию. Служба будет запущена незамедлительно. Процесс при этом не должен разветвляться.

1. В директории не заработало!
```bash
/etc/systemd/system/test_unit.target/test_unit.service
```

```bash
[root@bashscripts system]# rm -f test_unit.target/
rm: cannot remove вЂtest_unit.target/вЂ™: Is a directory
```
Даже после ребута, который, видимо, необходим.
```bash
sudo systemctl daemon-reload
```

Запустилось когда перенeс файл на диреторию выше.
```bash
mv /etc/systemd/system/test_unit.target/test_unit.service /etc/systemd/system/test_unit.service
```
**Вопрос: Почему не заработало по имени диретории, а по имени файла заработало?**

Прироста лога я не увидел, и подумал что скрипт должен быть в бесконечном цикле.
**Вопрос: А скрипт должен быть в бесконечном цикле?**

Вот первый рабочий вариант
```bash
#!/bin/bash
filename1=/var/log/audit/audit.log
word1=root
key=1

while [ $key -gt 0 ]
do
tail -n100 $filename1 | grep $word1 | tail -n1 >> /home/vagrant/logofsearchig.log
for i in {1..5}; do echo -n '!'; sleep 1; done
done
```
Тут лежит скрипт
```bash
[root@bashscripts vagrant]# pwd
/home/vagrant
[root@bashscripts vagrant]# ll
total 276
-rw-rw-r--. 1 vagrant vagrant 263208 Nov 13 05:06 hw6
-rwxrwxr-x. 1 vagrant vagrant    222 Nov 13 05:17 locking.sh
-rw-r--r--. 1 root    root      3878 Nov 13 05:18 logofsearchig.log
-rw-rw-r--. 1 vagrant vagrant    447 Nov 12 20:16 lookingfortheword
-rw-rw-r--. 1 vagrant vagrant   2505 Nov 13 05:21 README.md
```
Тут unit-файл, и перезагрузил systemctl `daemon-reload` на всякий случай.
```bash
[root@bashscripts vagrant]# ll /etc/systemd/system
drwxr-xr-x. 2 root root   32 May 12  2018 basic.target.wants
...
-rw-r--r--. 1 root root  447 Nov 13 05:11 test_unit.service
```

```bash
[root@bashscripts vagrant]# systemctl start test_unit 
[root@bashscripts vagrant]# systemctl status test_unit 
в—Џ test_unit.service - Searching for the word from some log file. word and file will be mentioned further in /etc/sysconfig
   Loaded: loaded (/etc/systemd/system/test_unit.service; disabled; vendor preset: disabled)
   Active: active (running) since Tue 2018-11-13 05:24:53 UTC; 4s ago
 Main PID: 4512 (locking.sh)
   CGroup: /system.slice/test_unit.service
           в”њв”Ђ4512 /bin/bash /home/vagrant/locking.sh /var/log/audit/audit.log root
           в””в”Ђ4520 sleep 1

Nov 13 05:24:53 bashscripts systemd[1]: Started Searching for the word from some log file. word and file will be mentioned f...config.
Nov 13 05:24:53 bashscripts systemd[1]: Starting Searching for the word from some log file. word and file will be mentioned ...nfig...
Hint: Some lines were ellipsized, use -l to show in full.
```
Попробовал kill - сервис продолжает работать

Не понятно где искать лог, я думал var/log/ 
```bash
StandardOutput=syslog
StandardError=syslog
```
а он в tail -f /var/log/messages
Записался во время остановки.
**Вопрос: Как можно повлиять на частоту записи в лог, может можно ему файл персонального лога указать в unit?**
```bash
Nov 13 05:36:58 localhost systemd: Stopping Searching for the word from some log file. word and file will be mentioned further in /etc/sysconfig...
Nov 13 05:36:58 localhost locking.sh: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
Nov 13 05:36:58 localhost systemd: Stopped Searching for the word from some log file. word and file will be mentioned further in /etc/sysconfig.
```

К слову о файде конфигурации
*The recommended way to do this is to create a file /etc/sysconfig/myservice which contains your variables, and then load them with EnvironmentFile.*
https://serverfault.com/questions/413397/how-to-set-environment-variable-in-systemd-service
https://fedoraproject.org/wiki/Packaging:Systemd#EnvironmentFiles_and_support_for_.2Fetc.2Fsysconfig_files
```bash

```
Нашел хороший пример в системе sshd
Есть сервис и можно посмотрев его статус увидеть путь, где лежит unit файл
```bash
OPTIONS="-u0"
[root@bashscripts vagrant]# systemctl status sshd
в—Џ sshd.service - OpenSSH server daemon
   Loaded: loaded (/usr/lib/systemd/system/sshd.service; enabled; vendor preset: enabled)
```
В самом файле можно увидеть загрузку переменных
```bash
[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/sshd
```
А в этом файле - как определена переменные
```bash
SSH_USE_STRONG_RNG=0
OPTIONS="-u0"
```
Короче так должно быть
Переименование и копирование на место
```bash
cp lookingfortheword /etc/systemd/system/test_unit.service
```
Файл конфигурации
```bash
[root@bashscripts vagrant]# cat /etc/sysconfig/test_unit 
FILENAME_1=/var/log/audit/audit.log
WORD_1="root"
```
Перезапуск
```bash
[root@bashscripts vagrant]# systemctl stop test_unit                                   
Warning: test_unit.service changed on disk. Run 'systemctl daemon-reload' to reload units.
[root@bashscripts vagrant]# systemctl daemon-reload
[root@bashscripts vagrant]# systemctl stop test_unit
[root@bashscripts vagrant]# systemctl start test_unit                                  
[root@bashscripts vagrant]# systemctl status test_unit                                 
в—Џ test_unit.service - Searching for the word from some log file. word and file will be mentioned further in /etc/sysconfig
   Loaded: loaded (/etc/systemd/system/test_unit.service; disabled; vendor preset: disabled)
   Active: active (running) since Tue 2018-11-13 06:21:21 UTC; 4s ago
 Main PID: 7590 (locking.sh)
   CGroup: /system.slice/test_unit.service
           в”њв”Ђ7590 /bin/bash /home/vagrant/locking.sh /var/log/audit/audit.log root
```

Файл лога пишется. Результат работы можно посмотреть в файле hw6_task1
	
task1	3:26:50

---

#### Задание 2
Из epel установить spawn-fcgi и переписать init-скрипт на unit-файл. Имя сервиса должно так же называться.

Установка не смогла. Иду в Гугол.
```bash
[root@bashscripts vagrant]# yum install spawn-fcgi
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirror.reconn.ru
 * extras: mirror.reconn.ru
 * updates: dedic.sh
No package spawn-fcgi available.
Error: Nothing to do
[root@bashscripts vagrant]# 
```
Первая мысль, а epel есть в списке репозиториев? Вроде как нет
```bash
[root@bashscripts vagrant]# yum repolist
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirror.reconn.ru
 * extras: mirror.reconn.ru
 * updates: mirror.logol.ru
repo id                                                        repo name                                                        
base/7/x86_64                                                  CentOS-7 - Base                                                  
extras/7/x86_64                                                CentOS-7 - Extras
updates/7/x86_64                                               CentOS-7 - Updates                                               
```
Первая статья Гугла говорит, как установить epel
```bash
yum install epel-release
```
Установка смогла.
```bash
[root@bashscripts vagrant]# yum install spawn-fcgi   
...
  Installing : spawn-fcgi-1.6.3-5.el7.x86_64                                                                                      1/1 
  Verifying  : spawn-fcgi-1.6.3-5.el7.x86_64                                                                                      1/1 

Installed:
  spawn-fcgi.x86_64 0:1.6.3-5.el7                                                                                                     

Complete!
```
Что это вообще такое
https://vds-admin.ru/unix-commands/spawn-fcgi

Как бы первая идея была - написать просто запуск этой программы с какими то ключами как сервис.
Видимо все сложнее?

Если я верно понимаю, он ставится куда-то сюда
```bash
[root@bashscripts vagrant]# /etc/init.d/spawn-fcgi 
Usage: /etc/init.d/spawn-fcgi {start|stop|status|restart|condrestart|try-restart|reload|force-reload}
```

Вота какая-то статья по запуску
http://www.if-not-true-then-false.com/2009/install-nginx-php-5-3-and-fastcgi-on-centos-fedora-red-hat-rhel/

следуя ей, пытаюсь что-то запустить, понимания, что это за программа и зачем - пока нет
```bash
yum -y install nginx php php-mysql php-pgsql php-pecl-memcache fcgi spawn-fcgi
```
... Add Fast-CGI init script и потом запуск
1. `/etc/init.d/phpfgci start` мне кажется не верная команда
вот так сделал, права, и запуск, что накопировал
```bash
[root@bashscripts vagrant]# chmod +x /etc/init.d/phpfcgi
[root@bashscripts vagrant]# ll /etc/init.d/
total 48
-rw-r--r--. 1 root root 18104 Jan  2  2018 functions
-rwxr-xr-x. 1 root root  4334 Jan  2  2018 netconsole
-rwxr-xr-x. 1 root root  7293 Jan  2  2018 network
-rwxr-xr-x. 1 root root  1766 Nov 13 07:43 phpfcgi
-rw-r--r--. 1 root root  1160 Apr 11  2018 README
-rwxr-xr-x. 1 root root  2129 Feb  6  2014 spawn-fcgi
[root@bashscripts vagrant]# /etc/init.d/phpfcgi start
Reloading systemd:                                         [  OK  ]
Starting phpfcgi (via systemctl):                          [  OK  ]
```
Что-то запустилось
```bash
[root@bashscripts vagrant]# /etc/init.d/phpfcgi status
в—Џ phpfcgi.service - SYSV: PHP is an HTML-embedded scripting language
   Loaded: loaded (/etc/rc.d/init.d/phpfcgi; bad; vendor preset: disabled)
   Active: active (running) since Tue 2018-11-13 07:47:19 UTC; 5min ago
     Docs: man:systemd-sysv-generator(8)
  Process: 14872 ExecStart=/etc/rc.d/init.d/phpfcgi start (code=exited, status=0/SUCCESS)
   CGroup: /system.slice/phpfcgi.service
           в”њв”Ђ14881 /usr/bin/php-cgi
           в”њв”Ђ14883 /usr/bin/php-cgi
           в”њв”Ђ14884 /usr/bin/php-cgi
           в”њв”Ђ14885 /usr/bin/php-cgi
           в”њв”Ђ14886 /usr/bin/php-cgi
           в””в”Ђ14887 /usr/bin/php-cgi

Nov 13 07:47:18 bashscripts systemd[1]: Starting SYSV: PHP is an HTML-embedded scripting language...
Nov 13 07:47:19 bashscripts phpfcgi[14872]: Starting service:spawn-fcgi: child spawned successfully: PID: 14881
Nov 13 07:47:19 bashscripts systemd[1]: Started SYSV: PHP is an HTML-embedded scripting language.
Nov 13 07:47:19 bashscripts phpfcgi[14872]: [  OK  ]
```
4. Configure nginx
5. Start FastCGI and nginx services
Тут не смог запустить `nginx` потому что не понятно, где его запускать
Его нет ни в /etc/init.d/ ни в systemctl
```bash
/etc/init.d/phpfcgi start
/etc/init.d/nginx start
```

**Вопрос: Как запущен nginx? Это сервис systemd или init.d? Как остановить/перезагрузить?**
```bash
[root@bashscripts vagrant]# ps axu | grep nginx 
nginx    16086  0.0  6.1 265020 11400 ?        Ss   08:04   0:00 /usr/bin/php-cgi
nginx    16088  0.0  2.5 265020  4680 ?        S    08:04   0:00 /usr/bin/php-cgi
nginx    16089  0.0  3.6 265176  6724 ?        S    08:04   0:00 /usr/bin/php-cgi
nginx    16090  0.0  3.0 265020  5564 ?        S    08:04   0:00 /usr/bin/php-cgi
nginx    16091  0.0  3.0 265020  5564 ?        S    08:04   0:00 /usr/bin/php-cgi
nginx    16092  0.0  2.5 265020  4680 ?        S    08:04   0:00 /usr/bin/php-cgi
root     16149  0.0  1.1 120800  2120 ?        Ss   08:05   0:00 nginx: master process nginx
nginx    16150  0.0  1.9 121200  3588 ?        S    08:05   0:00 nginx: worker process
nginx    16151  0.0  2.0 121336  3828 ?        S    08:05   0:00 nginx: worker process
root     16498  0.0  0.5  12520   976 pts/1    R+   08:10   0:00 grep --color=auto nginx
```
Самое интересное, страница открывается даже если эта штука выключена.
```bash
[root@bashscripts vagrant]# /etc/init.d/spawn-fcgi stop 
Stopping spawn-fcgi (via systemctl):                       [  OK  ]
```
Возвращаюсь сюда 
https://www.nginx.com/resources/wiki/start/topics/examples/freebsdspawnfcgi/
Что все это значит - не понятно
```bash
[root@bashscripts vagrant]# FCGI_CHILDREN=3
[root@bashscripts vagrant]# PROCESS_NAME=lua
[root@bashscripts vagrant]# SERVER_SOCKET=/tmp/fcgi.socket
[root@bashscripts vagrant]# SERVER_PID=/tmp/fcgi.pid
[root@bashscripts vagrant]# SERVER_USER=nginx
[root@bashscripts vagrant]# SERVER_GROUP=nginx
[root@bashscripts vagrant]# FCGI_PROCESS=/usr/local/php-cgi
[root@bashscripts vagrant]# /usr/bin/spawn-fcgi -s $SERVER_SOCKET -P $SERVER_PID -u $SERVER_USER -g $SERVER_GROUP -F $FCGI_CHILDREN -
f $FCGI_PROCESS
spawn-fcgi: child spawned successfully: PID: 18065
spawn-fcgi: child spawned successfully: PID: 18067
spawn-fcgi: child spawned successfully: PID: 18068
[root@bashscripts vagrant]# 
```

Хочу попробовать запустить через init.d
```bash
[root@bashscripts vagrant]# vi /etc/sysconfig/spawn-fcgi 
...
ERVER_USER=nginx
SERVER_GROUP=nginx
SERVER_SOCKET=/tmp/fcgi.socket
FCGI_CHILDREN=3
SERVER_PID=/tmp/fcgi.pid
FCGI_PROCESS=/usr/bin/php-cgi
#OPTIONS="-u $SERVER_USER -g $SERVER_GROUP -s $SERVER_SOCKET -S -M 0600 -C 32 -F $FCGI_CHILDREN -P $SERVER_PID -- /usr/bin/php-cgi"
OPTIONS="-u nginx -g nginx -s /tmp/fcgi.socket -S -M 0600 -C 32 -F 1 -P /tmp/fcgi.pid -- /usr/bin/php-cgi"
```
Тут какая то проблема, гугл в помощь
https://www.linode.com/community/questions/4348/unable-to-restart-spawn-fcgi
```bash
Nov 15 08:45:39 bashscripts spawn-fcgi[19529]: Starting spawn-fcgi: spawn-fcgi: socket is already in use, can't spawn
```

Поудалял какие-то процессы, и что-то запустилось.
```bash
[root@bashscripts vagrant]# ps -e | grep php
18067 ?        00:00:00 php-cgi
18068 ?        00:00:00 php-cgi
[root@bashscripts vagrant]# kill 18067
[root@bashscripts vagrant]# kill 18068
[root@bashscripts vagrant]# ps -e | grep php
[root@bashscripts vagrant]# /etc/init.d/spawn-fcgi start
Starting spawn-fcgi (via systemctl):                       [  OK  ]
```
Как бы вот стату, а что это и зачем - не ясно.
**Вопрос: Я запустил что-то вручную, что привело к занятым сокетам?**

**Вопрос: Что делает spawn-fcgi и как проверить, что за верным статусом есть и осязаемая функциональность?**
```bash
[root@bashscripts vagrant]# /etc/init.d/spawn-fcgi status
в—Џ spawn-fcgi.service - LSB: Start and stop FastCGI processes
   Loaded: loaded (/etc/rc.d/init.d/spawn-fcgi; bad; vendor preset: disabled)
   Active: active (running) since Thu 2018-11-15 08:55:05 MSK; 3min 12s ago
     Docs: man:systemd-sysv-generator(8)
  Process: 20392 ExecStart=/etc/rc.d/init.d/spawn-fcgi start (code=exited, status=0/SUCCESS)
   CGroup: /system.slice/spawn-fcgi.service
           в”њв”Ђ20404 /usr/bin/php-cgi
           в”њв”Ђ20406 /usr/bin/php-cgi
           ....
Nov 15 08:55:05 bashscripts systemd[1]: Starting LSB: Start and stop FastCGI processes...
Nov 15 08:55:05 bashscripts spawn-fcgi[20392]: Starting spawn-fcgi: [  OK  ]
Nov 15 08:55:05 bashscripts systemd[1]: Started LSB: Start and stop FastCGI processes.           
```
И да, после перезагрузки сервиса - ничего не удалилось, процессы остались, новый запуск не удался.
Удаление процессов помогает.

Не сложный unit для сервиса со ссылкой на тот же конфиг, пришлось поудалять из предыдущего кучу строк Reload и Stop
```bash
[Unit]
Description=spawn-fcgi is strange service to some particular aims
After=network.target

[Service]
Type=simple
PIDFile=/home/vagrant/service.pid
EnvironmentFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi $OPTIONS
#ExecStop=/usr/bin/kill `/usr/bin/systemctl status spawn-fcgi | grep "successfully: PID" | awk '{print $11}'`
KillSignal=SIGTERM
KillMode=process

[Install]
WantedBy=multi-user.target
```

Но есть одна проблема, он не завершается по команде stop
```bash
ExecStop=/bin/kill -WINCH ${MAINPID} (code=exited, status=1/FAILURE)
```
или так
```bash
Nov 15 09:58:08 bashscripts kill[29058]: kill: cannot find process ""
```
Я написал команду для удаления процесса, но ведь сервис так не убить - еще больше ошибок пришло.

**Вопрос: Как остановить этот сервис? Какие бывают впринципе способы кроме /bin/kill -WINCH ${MAINPID} и почему не отрабатывает этот?**

На задание 2
3:13:02

---

#### Задание 3
Дополнить юнит-файл apache httpd возможность запустить несколько инстансов сервера с разными конфигами

Нашел сам юнит-файл
```bash
[root@bashscripts vagrant]# systemctl status httpd
в—Џ httpd.service - The Apache HTTP Server
   Loaded: loaded (/usr/lib/systemd/system/httpd.service; disabled; vendor preset: disabled)
...
[root@bashscripts vagrant]# cat /usr/lib/systemd/system/httpd.service
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/httpd
ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
ExecStop=/bin/kill -WINCH ${MAINPID}
KillSignal=SIGCONT
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

Если я верно понял, нужно использовать шаблон
http://rus-linux.net/MyLDP/boot/systemd_7_template_unit_files.html
```bash

```
Запутался в конфигах
```bash
/etc/sysconfig/httpd
/etc/httpd/conf/httpd.conf
```

Решил проверить, на что влияет конфиг - `/etc/httpd/conf/httpd.conf` - сменил порт `Listen 8080` и вот что увидел:
```bash
[root@bashscripts vagrant]# systemctl start httpd         
[root@bashscripts vagrant]# netstat -tlpn                 
            
tcp6       0      0 :::8080                 :::*                    LISTEN      6600/httpd                
```
Первая же идея тупо отключить ipv6 сработала:
```bash
[root@bashscripts vagrant]# systemctl stop httpd  
[root@bashscripts vagrant]# sysctl -w net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.all.disable_ipv6 = 1
[root@bashscripts vagrant]# sysctl -w net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6 = 1
[root@bashscripts vagrant]# systemctl start httpd                         
[root@bashscripts vagrant]# netstat -tlpn                                 
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 0.0.0.0:8080            0.0.0.0:*               LISTEN      6856/httpd
```
Тут все хорошо http://192.168.33.12:8080/ Testing 123.. вижу

Тут не через шаблон но подход стал понятен
https://lists.fedoraproject.org/pipermail/users/2013-August/439603.html

нужны 2 файла конфигурации с разными портами `Listen 8080` и сожет быть файлами логов. Пока только разные порты.
```bash
-rw-r--r--. 1 root root 11753 Nov 15 13:38 /etc/httpd/conf/httpd81.conf
-rw-r--r--. 1 root root 11755 Nov 15 13:50 /etc/httpd/conf/httpd82.conf
```

Пробую пошагово - тоесть меняю в конфиге опиции -f путь к файлу конфигурации - на файлы выше.
```bash
vi /etc/sysconfig/httpd
OPTIONS= -D81Servicesjcshcvvfewvcdhcdvcbebebe -f /etc/httpd/conf/httpd82.conf
```

Но вот беда, не все порты одинаково хороши.
**Вопрос: Почему на одном порту я могу поднять сервис, а на соседнем нет, хотя оба не занаты? Может как-то нужно создать сокет, прежде чем использовать его?**
```bash
Nov 15 13:41:09 bashscripts httpd[12541]: AH00558: httpd: Could not reliably determine the server's fully qualified domain name, usingNov 15 13:41:09 bashscripts httpd[12541]: (13)Permission denied: AH00072: make_sock: could not bind to address 0.0.0.0:82
Nov 15 13:41:09 bashscripts httpd[12541]: no listening sockets available, shutting down
Nov 15 13:41:09 bashscripts httpd[12541]: AH00015: Unable to open logs
```

```bash
[root@bashscripts vagrant]# netstat -tlpn                           
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 0.0.0.0:111             0.0.0.0:*               LISTEN      760/rpcbind         
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      16149/nginx: master 
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      4178/sshd           
tcp        0      0 127.0.0.1:25            0.0.0.0:*               LISTEN      1305/master         
tcp6       0      0 :::111                  :::*                    LISTEN      760/rpcbind         
tcp6       0      0 :::80                   :::*                    LISTEN      16149/nginx: master 
tcp6       0      0 :::22                   :::*                    LISTEN      4178/sshd           
tcp6       0      0 ::1:25                  :::*                    LISTEN      1305/master     
```

Поочереди сервис httpd запускается с разыми конфигами.
Теперь пробую запустить с разными EnvironmentFile
Так работает. Осталось сделать это как шаблон - в статье шаблоном бни файл становится после добавления переменных %i
```bash
EnvironmentFile=/etc/sysconfig/httpd81
EnvironmentFile=/etc/sysconfig/httpd82
```

```bash
[root@bashscripts vagrant]# systemctl start httpd@82.service           
Failed to start httpd@82.service: Unit not found.
```
Оказывается, должен существовать не просто юнит файл, а специальный шаблон, отличается именем `example@.service` и наличием %i внутри
https://www.digitalocean.com/community/tutorials/understanding-systemd-units-and-unit-files
```bash
[root@bashscripts vagrant]# cat /usr/lib/systemd/system/httpd@.service
[Unit]
...

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/httpd%i
PIDFile=/home/vagrant/httpd%i.pid
...
```
**Вопрос: Почему пришлось менять pid внутри конфигурационного файла httpd, а тот что в юнит файле не помог и вообще ни на что не повлиял?**

В юнит файле ссылка на следующий файл конфигурации /etc/sysconfig/httpd81 или /etc/sysconfig/httpd82 через %i
просто переменная определена и она подставится при запуске
```bash
OPTIONS= -Dhttpd81 -f /etc/httpd/conf/httpd81.conf
#или
OPTIONS= -Dhttpd81 -f /etc/httpd/conf/httpd82.conf
```
/etc/httpd/conf/httpd81.conf /etc/httpd/conf/httpd82.conf
Измененные строки:
```bash
PidFile "/var/run/httpd81.pid"
ServerName localhost
Listen 81 # 8080
ErrorLog "logs/error_81_log"
#IncludeOptional conf.d/*.conf
```
Причина столь долгих безуспешных попыток - кавычки - а точнее их отсутствие вокруг пути PidFile
Последнее не знаю зачем, на всякий случай и заработало
```bash
[root@bashscripts vagrant]# netstat -tlpn
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 0.0.0.0:111             0.0.0.0:*               LISTEN      760/rpcbind         
tcp        0      0 0.0.0.0:8080            0.0.0.0:*               LISTEN      14052/httpd         
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      16149/nginx: master 
tcp        0      0 0.0.0.0:81              0.0.0.0:*               LISTEN      14030/httpd
```


#### Задание 4
Очевидно, не хватило времени...Слишком долго я тупил с ковычками...
  
Otus. Администратор Linux.HW6t3   6:14:16 
Otus. Администратор Linux.HW6t2   3:13:02 
Otus. Администратор Linux.HW6     3:26:50