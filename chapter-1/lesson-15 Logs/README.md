### Сбор и анализ логов

#### Где-то с 255 строчки начинается очередная попытка, ибо текущая успехом не увенчалась.
И возможно там есть смысл искать решение ДЗ.

Настраиваем центральный сервер для сбора логов
в вагранте поднимаем 2 машины web и log
на web поднимаем nginx
на log настраиваем центральный лог сервер на любой системе на выбор
- journald
- rsyslog
- elk 
настраиваем аудит следящий за изменением конфигов нжинкса 

все критичные логи с web должны собираться и локально и удаленно
все логи с nginx должны уходить на удаленный сервер (локально только критичные)
логи аудита уходят ТОЛЬКО на удаленную систему


* развернуть еще машину elk
и таким образом настроить 2 центральных лог системы elk И какую либо еще
в elk должны уходить только логи нжинкса
во вторую систему все остальное

Я очень расчитываю сделать это ДЗ быcтрее чем обычно, поэтому беру машины из задания 11.

Пока я не знаю, как это будет проверяться, ибо Vagrent на windows накладывает определенную специфику.

Первое что вижу в примере - пересылка по имени узла.
Добавляем в hosts
```bash
192.168.33.12 webhost
192.168.33.13 loghos
```

На сервере loghos в /etc/rsyslog.conf
```bash
$ModLoad imudp
$UDPServerRun 514
```

На сервере webhost в /etc/rsyslog.conf
```bash
*.* @loghost:514
```

И некоторые логи стали приходить.
```bash
[root@loghost vagrant]# tcpdump -i eth1 port 514
19:44:42.403596 IP webhost.35758 > loghost.syslog: SYSLOG daemon.info, length: 68
19:44:42.403713 IP webhost.35758 > loghost.syslog: SYSLOG authpriv.notice, length: 235
```

```bash
[root@loghost vagrant]# tail -f /var/log/messages | grep webhost
Dec 25 19:39:49 webhost yum[8297]: Installed: 14:libpcap-1.5.3-11.el7.x86_64
Dec 25 19:39:49 webhost yum[8297]: Installed: 14:tcpdump-4.9.2-3.el7.x86_64
Dec 25 19:44:42 webhost systemd: Stopping System Logging Service...
Dec 25 19:44:42 webhost rsyslogd: [origin software="rsyslogd" swVersion="8.24.0-34.el7" x-pid="7998" x-info="http://www.rsyslog.com"] exiting on signal 15.
Dec 25 19:44:42 webhost systemd: Stopped System Logging Service.
Dec 25 19:44:42 webhost systemd: Starting System Logging Service...
Dec 25 19:44:42 webhost rsyslogd: [origin software="rsyslogd" swVersion="8.24.0-34.el7" x-pid="28799" x-info="http://www.rsyslog.com"] start
Dec 25 19:44:42 webhost systemd: Started System Logging Service.
```

Пока только в настройках /etc/nginx/nginx.conf удалось что-то послать на удаленный хост.
```bash
[root@webhost vagrant]# vi /etc/nginx/nginx.conf
error_log syslog:server=loghost debug;
```

```bash
[root@webhost vagrant]# vi /etc/nginx/nginx.conf
Dec 25 20:00:24 webhost nginx: 2018/12/25 20:00:24 [debug] 29121#0: epoll timer: 65000
```

C access не получилось, ошибка при перезагрузке сервиса.
```bash
[root@webhost vagrant]# vi /etc/nginx/nginx.conf
access_log syslog:server=loghost,facility=local7,tag=nginx,severity=info combined;
```

Такая ошибка, пока не понятно почему.
```bash
[root@webhost vagrant]# journalctl -xe
-- Defined-By: systemd
-- Support: http://lists.freedesktop.org/mailman/listinfo/systemd-devel
-- 
-- Unit nginx.service has begun shutting down.
Dec 25 19:55:36 webhost systemd[1]: Stopped The nginx HTTP and reverse proxy server.
-- Subject: Unit nginx.service has finished shutting down
-- Defined-By: systemd
-- Support: http://lists.freedesktop.org/mailman/listinfo/systemd-devel
-- 
-- Unit nginx.service has finished shutting down.
Dec 25 19:55:36 webhost systemd[1]: Starting The nginx HTTP and reverse proxy server...
-- Subject: Unit nginx.service has begun start-up
-- Defined-By: systemd
-- Support: http://lists.freedesktop.org/mailman/listinfo/systemd-devel
-- 
-- Unit nginx.service has begun starting up.
Dec 25 19:55:36 webhost nginx[29090]: nginx: [emerg] "access_log" directive is not allowed here in /etc/nginx/nginx.conf:5
Dec 25 19:55:36 webhost nginx[29090]: nginx: configuration file /etc/nginx/nginx.conf test failed
Dec 25 19:55:36 webhost systemd[1]: nginx.service: control process exited, code=exited status=1
Dec 25 19:55:36 webhost systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
-- Subject: Unit nginx.service has failed
-- Defined-By: systemd
-- Support: http://lists.freedesktop.org/mailman/listinfo/systemd-devel
-- 
-- Unit nginx.service has failed.
-- 
-- The result is failed.
Dec 25 19:55:36 webhost systemd[1]: Unit nginx.service entered failed state.
Dec 25 19:55:36 webhost systemd[1]: nginx.service failed.
Dec 25 19:55:36 webhost polkitd[1760]: Unregistered Authentication Agent for unix-process:29079:393472 (system bus name :1.83, object path /org/freedesktop/
Dec 25 19:56:07 webhost polkitd[1760]: Registered Authentication Agent for unix-process:29095:396577 (system bus name :1.84 [/usr/bin/pkttyagent --notify-fd
Dec 25 19:56:07 webhost systemd[1]: Starting The nginx HTTP and reverse proxy server...
-- Subject: Unit nginx.service has begun start-up
-- Defined-By: systemd
-- Support: http://lists.freedesktop.org/mailman/listinfo/systemd-devel
-- 
-- Unit nginx.service has begun starting up.
Dec 25 19:56:07 webhost nginx[29102]: nginx: [emerg] "access_log" directive is not allowed here in /etc/nginx/nginx.conf:5
Dec 25 19:56:07 webhost nginx[29102]: nginx: configuration file /etc/nginx/nginx.conf test failed
Dec 25 19:56:07 webhost systemd[1]: nginx.service: control process exited, code=exited status=1
Dec 25 19:56:07 webhost systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
-- Subject: Unit nginx.service has failed
-- Defined-By: systemd
-- Support: http://lists.freedesktop.org/mailman/listinfo/systemd-devel
-- 
-- Unit nginx.service has failed.
-- 
-- The result is failed.
Dec 25 19:56:07 webhost systemd[1]: Unit nginx.service entered failed state.
Dec 25 19:56:07 webhost systemd[1]: nginx.service failed.
Dec 25 19:56:07 webhost polkitd[1760]: Unregistered Authentication Agent for unix-process:29095:396577 (system bus name :1.84, object path /org/freedesktop
```

**Вопрос: Есть идеи, почему так происходит?**

Я вообще, питаю нажежду, что посредством самого rsyslog я смогу взять какой-то произволный текстовый файл, и отправлять его содержимое на сервер по мере поступления.
А нет через программу, создающую лог, завернуть его в rsyslog.

Я не нашел где настраиватеся лог access_log. grep -r по etc показал что все входжения - закомментрованы, 
и попыка раскоментировать, приводит к ошибке при перезагрузке.

На самом деле, при внимательном рассмотрении записей в журнале, проблема с форматом.
```bash
root@webhost vagrant]# journalctl -xe
Dec 25 22:01:18 webhost nginx[29959]: nginx: [emerg] unknown log format "upstream_time" in /etc/nginx/nginx.conf:43
```

по-умолчанию путь `/var/log/nginx/access.log`
изменил на `/var/log/nginx/webhost.access.log`

по-умолчанию  формат `combined` , но что это значит, где регулировать уровень логирования - пока не понятно, [но тут описано][1].

```bash
    server {
        listen       8080;
        server_name  nginx;

        #charset koi8-r;

        access_log  /var/log/nginx/webhost.access.log;

        location / {
            root   html;
            index  index.html index.htm;
        }
```

В секции http можно определять форматы логов, не абы где, иначе
```bash
Dec 25 22:13:55 webhost nginx[30032]: nginx: [emerg] "log_format" directive is not allowed here in /etc/nginx/nginx.conf:14
```

Так вот тут есть закоментриванный формат, я его немного поменял, добавив количество сессий и порядковый номер обращения.
```bash
http {
    include       mime.types;
    default_type  application/octet-stream;

    log_format  main  '$connection $connection_requests $remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
```

Ошибка стразу. Секция важна.
```bash
9 1 127.0.0.1 - - [25/Dec/2018:22:17:24 +0000] "GET / HTTP/1.1" 200 108 "-" "curl/7.29.0" "-"
```

В конце дописан формат.
```bash
        access_log  /var/log/nginx/webhost.access.log main;
```

Удалось настроить разноуровневое логирование локально и удаленно, думаю, не проблема создать третий файл, 
и не nginx-ом слать лог а rsyslog-ом пересылать файл.
```bash
error_log syslog:server=loghost debug;
error_log /var/log/nginx/error.log crit;
```

Еще раз:
все (error debug + access_log) логи с nginx должны уходить на удаленный сервер (локально только критичные - уровень - crit)

Теперь бы еще access.log отправить. Настроил так.
```bash
        access_log  /var/log/nginx/webhost.access.log main;
        access_log  syslog:server=loghost,facility=local7,tag=nginx,severity=info main;
```

```bash
[root@webhost vagrant]# tail -f /var/log/nginx/webhost.access.log 
2 1 127.0.0.1 - - [25/Dec/2018:22:51:54 +0000] "GET / HTTP/1.1" 200 108 "-" "curl/7.29.0" "-"
```

```bash
[root@loghost vagrant]# tail -f /var/log/messages 
Dec 25 22:51:54 webhost nginx: 2 1 127.0.0.1 - - [25/Dec/2018:22:51:54 +0000] "GET / HTTP/1.1" 200 108 "-" "curl/7.29.0" "-"
Dec 25 22:51:54 webhost nginx: 2018/12/25 22:51:54 [info] 30235#0: *2 client 127.0.0.1 closed keepalive connection
```

Видно что сообщения приходят в общую кучу /var/log/messages

Следующее,
все критичные логи с web должны собираться и локально и удаленно.
Я это понял так, чтоб переслать все локальные логи на удаленный сервер.
И тут не понятно, /var/log/messages или journalctl или вообще все файлики из var/log/

Дело сдвинулось только так и то не сильно. На сервере.
```bash
# Log remote hosts to separate log file
$template PerHostLog,"/var/log/remote-hosts/%HOSTNAME%/%PROGRAMNAME%.log"
$template RemoteHostFileFormat,"%TIMESTAMP% %HOSTNAME% %syslogfacility-text% %syslogtag%%msg:::sp-if-no-1st-sp%%msg:::space-cc,drop-last-lf%\n"
:inputname, isequal, "imudp" ?PerHostLog;RemoteHostFileFormat
& ~
```

Спустя некторое время (1,5 часа) получаем файлы. 
```bash
[root@loghost vagrant]# tail -f /var/log/remote-hosts/webhost/
nginx.log           rsyslogd.log        systemd.log         
polkitd.log         sshd.log            systemd-logind.log
```
аудита (файла) нет. хотя модуль импортировал как тут.
https://rtfm.co.ua/rsyslog-dobavlenie-nablyudeniya-za-fajlom-v-konfiguraciyu/

Считаю это провалом, а дальнейшие инсинуации - бессмысленными.

Я перезугружу витруальный стенд с нуля, настрою первым делем переселку логов из файлов, чтоб перед дампом ничего лишнего не мельтешило,
разберусь с этим наконец, и потом из уже понятного доделаю остальную часть задания.

---

Перезагрузка.

---

1. Все критичные логи с web должны собираться и локально и удаленно.

По мне - все логи, ибо отсылая из файла, как я хочу, мы сами определим критичность($InputFileSeverity).

Нужно отправить логи nginx не из его настроек, как было выше, а переслать файлы.
Тогда эти файлы буду и локально и удаленно.

```bash
[root@webhost vagrant]# tail -f /var/log/nginx/
access.log  error.log  
```

В прошлом шаге мы научились запускать сервер на прослушивание и настраивать шаблон раскидывания логов по директориям.
Воспользуемся наработками.


```bash
[root@loghost vagrant]# cat /etc/rsyslog.conf
...
# Provides UDP syslog reception
$ModLoad imudp
$UDPServerRun 514

$template PerHostLog,"/var/log/remote-hosts/%HOSTNAME%/%PROGRAMNAME%.log"
$template RemoteHostFileFormat,"%TIMESTAMP% %HOSTNAME% %syslogfacility-text% %syslogtag%%msg:::sp-if-no-1st-sp%%msg:::space-cc,drop-last-lf%\n"
:inputname, isequal, "imudp" ?PerHostLog;RemoteHostFileFormat
& ~
```

```bash
[root@loghost vagrant]# netstat -nlp | grep rsys
udp        0      0 0.0.0.0:514             0.0.0.0:*                           4301/rsyslogd       
udp6       0      0 :::514                  :::*                                4301/rsyslogd       
```

```bash
[root@loghost vagrant]# tail -n1 /var/log/remote-hosts/192.168.33.12/.log
Jan 30 20:23:09 192.168.33.12 local4  192.168.33.1 - - [30/Jan/2019:20:23:05 +0000] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36"
```

Уже пропустил кучу вариантов кривой настройки. Если в шаблоне указать только %msg% - имена файлов могут быть .log -.log \..\ и прочие.
Я пока закономерности не увидел. Ключа InputFile c указанием программы - нет
```bash
[root@webhost vagrant]# cat /etc/rsyslog.d/files-log-nginx.conf
# Nginx files to syslog server

$ModLoad imfile

$InputFileName /var/log/nginx/error.log
$InputFileTag nginx:
$InputFileStateFile stat-nginx-error
$InputFileSeverity error
$InputFileFacility local1
$InputFilePollInterval 1
$InputRunFileMonitor

# access log
$InputFileName /var/log/nginx/access.log
$InputFileTag nginx:
$InputFileStateFile stat-nginx-access
$InputFileSeverity notice
$InputFileFacility local2
$InputFilePollInterval 1
$InputRunFileMonitor

$template error, "%programname% %msg%"
$template access, "%programname% %msg%"

local1.* @192.168.33.13;error
local2.* @192.168.33.13;access
```

Вот такая конфигурация $template error, "%programname% %msg%" дала результат следующий и странный.
Ок. Имя типа есть. Но access лог лежит в 192.168.33.12.log а error в 2019.log

```bash
[root@loghost vagrant]# ls -la /var/log/remote-hosts/nginx/
192.168.33.12.log  2019.log           
[root@loghost vagrant]# ls -la /var/log/remote-hosts/nginx/../nginx/
192.168.33.12.log  2019.log     
```
И это странно. Но файлы посланы. Это успех.
**Вопрос: Как сделать красиво, чтоб имя хоста было (или ip) и имя программы и имя файла(access.log error.log) и это аккуратно на сервере клалось да еще и не дублировалось так хитро?**

Тела логов.
```bash
[root@loghost vagrant]# tail /var/log/remote-hosts/nginx/2019.log
Jan 30 21:10:05 nginx user 2019/01/30 21

[root@loghost vagrant]# tail /var/log/remote-hosts/nginx/192.168.33.12.log 
Jan 30 21:11:15 nginx user 192.168.33.12 - - [
```
Я вижу сходство. 
nginx - 4 поле
2019 и 192.168.33.12 - 6 поле в логе

Отправляем в формате
```bash
template error, "%HOSTNAME% %programname% %msg%"
```

Принимаем и формируем новый фоомат так
```bash
$template RemoteHostFileFormat,"%TIMESTAMP% %HOSTNAME% %syslogfacility-text% %syslogtag%%msg:::sp-if-no-1st-sp%%msg:::space-cc,drop-last-lf%\n"
```

Сократил шаблоны
```bash
...
template error, "%msg%"
...
$template RemoteHostFileFormat,"%syslogfacility-text% %syslogtag%%msg:::sp-if-no-1st-sp%%msg:::space-cc,drop-last-lf%\n"
```

Но тут стабильно столбцы из лога будут именами файлов.
```bash
[root@loghost vagrant]# tail /var/log/remote-hosts/192.168.33.12/
2019.log            Connection.log      Content-Type.log    ETag.log            -.log
Accept-Ranges.log   Content-Length.log  Date.log            Last-Modified.log   Server.log
[root@loghost vagrant]# tail /var/log/remote-hosts/192.168.33.12/-.log 
user - - [30/Jan/2019:21:26:34 +0000] "GET / HTTP/1.1" 200 108 "-" "curl/7.29.0"
```

И куча пустых файлов.
```bash
[root@loghost vagrant]# ls -la /var/log/remote-hosts/192.168.33.12/
total 16
drwx------. 2 root root   207 Jan 30 21:26 .
drwx------. 3 root root    27 Jan 30 21:25 ..
-rw-------. 1 root root 11247 Jan 30 21:26 2019.log
-rw-------. 1 root root     0 Jan 30 21:26 Accept-Ranges.log
-rw-------. 1 root root     0 Jan 30 21:26 Connection.log
-rw-------. 1 root root     0 Jan 30 21:26 Content-Length.log
-rw-------. 1 root root     0 Jan 30 21:26 Content-Type.log
-rw-------. 1 root root     0 Jan 30 21:26 Date.log
-rw-------. 1 root root     0 Jan 30 21:26 ETag.log
-rw-------. 1 root root     0 Jan 30 21:26 Last-Modified.log
-rw-------. 1 root root    81 Jan 30 21:26 -.log
-rw-------. 1 root root     0 Jan 30 21:26 Server.log
```
Получается %HOSTNAME% не от чего не завист и берется верный всегда, хотя мы его явно не указываем, а вот %programname% берется из лога, а как его задать отдельно - не ясно.
Наверняка можно распарсить условияви входжения чего то в лог по файлам с конкретными именами, я думаю, но я хотел вот так, ибо остальные программы настроенные через свою конфигурацию на логирование удаленное - проблем с подстановкой своего имени не имели прошлый раз. Поэтому на приеме шаблон хороший.

Каким то внеземным вмешательством слабоумие и отвага победили на этот раз, и путем упрямства, а также перебором всех подвернувшихся вариантов в сети,
желанный результат был достигнут.

Вот так теперь хранятся наши файлы.
История умалчивает, почему rsyslog в качества макросов подставляет слова из лога, (выше я писал о сходсвте имен и полей логов)

**Вопрос: Да, а почему rsyslog в качества макросов %HOSTNAME%/%programname% подставляет слова из полученного лога?**

Воспользовавшись этой странностью ("192.168.33.12 error %msg%"), получил заветное разделение файлов.

**Вопрос: Но вопрос выше, все еще актуален, как такое же разделение по хостам и програамам сделать правильно при передаче файла?**

```bash
[root@loghost vagrant]# cat /var/log/remote-hosts/192.168.33.12/
access.log  error.log   
[root@loghost vagrant]# cat /var/log/remote-hosts/192.168.33.12/access.log 
user access 192.168.33.12 - - [30/Jan/2019:22:24:09 +0000] "GET / HTTP/1.1" 200 108 "-" "curl/7.29.0"
user access 192.168.33.12 - - [30/Jan/2019:22:25:19 +0000] "GET / HTTP/1.1" 200 108 "-" "curl/7.29.0"
user access 192.168.33.12 - - [30/Jan/2019:22:25:19 +0000] "GET / HTTP/1.1" 200 108 "-" "curl/7.29.0"
user access 192.168.33.12 - - [30/Jan/2019:22:25:20 +0000] "GET / HTTP/1.1" 200 108 "-" "curl/7.29.0"
[root@loghost vagrant]# cat /var/log/remote-hosts/192.168.33.12/error.log 
user error 2019/01/30 22:24:01 [notice] 28769#0: signal 3 (SIGQUIT) received, shutting down
user error 2019/01/30 22:24:01 [debug] 28769#0: wake up, sigio 0
```

Конфиг стоило бы высечь в камне, учитывая как много я потратил времени, чтоб его получить.

Приемная сторона

```bash
[root@loghost vagrant]# cat /etc/rsyslog.conf | grep -v '^ *#' | grep -v "^$"
$ModLoad imuxsock # provides support for local system logging (e.g. via logger command)
$ModLoad imjournal # provides access to the systemd journal
$ModLoad imudp
$UDPServerRun 514
$template PerHostLog,"/var/log/remote-hosts/%HOSTNAME%/%programname%.log"
$template RemoteHostFileFormat,"%syslogfacility-text% %syslogtag%%msg:::sp-if-no-1st-sp%%msg:::space-cc,drop-last-lf%\n"
:inputname, isequal, "imudp" ?PerHostLog;RemoteHostFileFormat
& ~
$WorkDirectory /var/lib/rsyslog
$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat
$IncludeConfig /etc/rsyslog.d/*.conf
$OmitLocalLogging on
$IMJournalStateFile imjournal.state
*.info;mail.none;authpriv.none;cron.none                /var/log/messages
authpriv.*                                              /var/log/secure
mail.*                                                  -/var/log/maillog
cron.*                                                  /var/log/cron
*.emerg                                                 :omusrmsg:*
uucp,news.crit                                          /var/log/spooler
local7.*                                                /var/log/boot.log
```

Передающая сторона

```bash
[root@webhost vagrant]# cat /etc/rsyslog.d/files-log-nginx.conf | grep -v '^ *#' | grep -v "^$"
$ModLoad imfile
$InputFileName /var/log/nginx/error.log
$InputFileTag nginx_error:
$InputFileStateFile stat-nginx-error
$InputFileSeverity error
$InputFileFacility local1
$InputFilePollInterval 1
$InputRunFileMonitor

$InputFileName /var/log/nginx/access.log
$InputFileTag nginx_access:
$InputFileStateFile stat-nginx-access
$InputFileSeverity notice
$InputFileFacility local2
$InputFilePollInterval 1
$InputRunFileMonitor
$template error, "192.168.33.12 error %msg%"
$template access, "192.168.33.12 access %msg%"
local1.* @192.168.33.13;error
local2.* @192.168.33.13;access
```

---

2. все логи с nginx должны уходить на удаленный сервер (локально только критичные)

Во-первых, не понятно, что такое критичные логи.
И все логи с nginx должны уходить на удаленный сервер - они уже уходят, но уходят все, без деления.

Похоже, речь просто про категорию, critical, и наверняка есть уже определенные события с таким уровнем Severity
Наверное, его как и некоторые существующие логи можно зафильтровать в отдельную директорию, или как в нашем случае - удаленно.
Заодно, посмотрим, как шаблон распределения отработает.

Видим фильтры - делаем по аналогии.
```bash
local7.*                                                /var/log/boot.log

*.crit @192.168.33.13
```

Заморачиваться с генерированием логов долго не буду, воспользуюсь logger-ом

Передающая сторона

```bash
[root@webhost vagrant]# logger -p crit test critical log
```

Принимающая сторона

```bash
[root@loghost vagrant]# tail -f /var/log/remote-hosts/webhost/vagrant.log 
user vagrant: test critical log
```

Не знаю, что тут еще нужно.

---

3. Логи аудита уходят ТОЛЬКО на удаленную систему

Вот к этому, я , видимо еще не подступался.

В сети попеременно натыкался на пару вариантов - через дополнительные программы и чере изменение facility для аудита.
Я золотую медаль не претендую, так что хватит пока одного, последнего.

Изменить args с LOG_USER или INFO на LOG_LOCAL6
```bash
[root@webhost vagrant]# vi /etc/audisp/plugins.d/syslog.conf
# This file controls the configuration of the syslog plugin.
# It simply takes events and writes them to syslog. The
# arguments provided can be the default priority that you
# want the events written with. And optionally, you can give
# a second argument indicating the facility that you want events
# logged to. Valid options are LOG_LOCAL0 through 7, LOG_AUTH,
# LOG_AUTHPRIV, LOG_DAEMON, LOG_SYSLOG, and LOG_USER.

active = yes
direction = out
path = builtin_syslog
type = builtin
args = LOG_LOCAL6
format = string
```

Отключить локальное логирование
```bash
[root@webhost vagrant]# vi /etc/audit/auditd.conf 
#
# This file controls the configuration of the audit daemon
#

local_events = yes
write_logs = no # ТУТ
```

Перезапустить сервисы
```bash
systemctl restart rsyslog
service auditd restart
```

Замечу, что так не перезагружается.
```bash
[root@webhost vagrant]# systemctl restart auditd
Failed to restart auditd.service: Operation refused, unit auditd.service may be requested by dependency only (it is configured to refuse manual start/stop).
See system logs and 'systemctl status auditd.service' for details.
```

И собственно, открыть tail -f оба файла, убедиться в работе.

Передающая сторона
```bash
[root@webhost vagrant]# tail -f /var/log/audit/audit.log
```

Принимающая сторона
```bash
[root@loghost vagrant]# tail -f /var/log/remote-hosts/webhost/audispd.log
```

Боюсь начинать считать потраченное время.
Не успел посмотреть подробнее journald и elk.

2:46:55 + 2:22:49 - Первая попытка (05:09:44)
4:51:17 - Вторая

итого
10:01:01

Команд не много, так что не плохо бы это все в плейбук добавить.

Еще 2:26:59 на создание и отладку плейбуков.

Сразу предупреждаю, у меня Vagrant на Windows, поэтому схема специфическая - через дополнение vagrant-guest_ansible (0.0.4, global)

По сути, на каждом хосте ставится отдельный ansible и запускается локальный сценарий на этот узел.

Перезагружал несколько раз, у меня работало. Честно.

После загрузки узлов нужно ввести пару команд для проверки.

```bash
[root@webhost1 vagrant]# curl 192.168.33.12:8080
[root@webhost1 vagrant]# logger -p crit test critical log
```

И на приемной стороне должно получиться следующее:
```bash
[root@loghost1 vagrant]# ll /var/log/remote-hosts/*/
/var/log/remote-hosts/192.168.33.12/:
total 16
-rw-------. 1 root root   204 Feb  3 21:36 access.log
-rw-------. 1 root root 11449 Feb  3 21:36 error.log

/var/log/remote-hosts/webhost1/:
total 16
-rw-------. 1 root root 11846 Feb  3 21:36 audispd.log
-rw-------. 1 root root    32 Feb  3 21:26 vagrant.log
```

Возможно он частично пересекается с предыдущими.

**Вопрос: Почему у меня один шаблон для получения и распределения логов с удаленных хостов, а по факту один и тот же узел отправляет логи, а сервер использует в одном случае имя, а в другом - IP?**


---

[1]: https://nginx.org/ru/docs/http/ngx_http_log_module.html
[2]: https://blog.heroix.com/blog/configuring-and-collecting-syslog
[3]: 
[4]: 
[5]: 
[6]: 