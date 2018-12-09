### Управление пакетами. Дистрибьюция софта. 

Домашнее задание
Размещаем свой RPM в своем репозитории
1) Создать свой RPM пакет (можно взять свое приложение, либо собрать, например, апач с определенными опциями)

2) Создать свой репозиторий и разместить там ранее собранный RPM


[Методичка][1]


---

Задание 1.
Установка необходимых пакетов

```bash
Installed:
  createrepo.noarch 0:0.9.9-28.el7     redhat-lsb-core.x86_64 0:4.1-27.el7.centos.1     rpm-build.x86_64 0:4.11.3-35.el7    
  rpmdevtools.noarch 0:8.3-5.el7  
```

Загрузка пакета для экспериментов
```bash
wget https://nginx.org/packages/centos/7/SRPMS/nginx-1.14.1-1.el7_4.ngx.src.rpm
```

Установка
```bash
[root@ReposituryRPM vagrant]# rpm -i nginx-1.14.1-1.el7_4.ngx.src.rpm 
warning: nginx-1.14.1-1.el7_4.ngx.src.rpm: Header V4 RSA/SHA1 Signature, key ID 7bd9bf62: NOKEY
warning: user builder does not exist - using root
warning: group builder does not exist - using root
```

И ничего. Он не поставился.
```bash
[root@ReposituryRPM vagrant]# rpm -qa | grep nginx
[root@ReposituryRPM vagrant]# 
```

Если пользователя нет - нужно его создать и залогиниться им.
```bash
[root@ReposituryRPM vagrant]# adduser builder
[root@ReposituryRPM vagrant]# passwd builder
Changing password for user builder.
New password: 
BAD PASSWORD: The password is shorter than 8 characters
Retype new password: 
passwd: all authentication tokens updated successfully.
[root@ReposituryRPM vagrant]# gpasswd -a builder wheel
Adding user builder to group wheel
[root@ReposituryRPM vagrant]# su - builder
```

Коллеги кодсказывают, нужно что-то вроде дерева каталогов создать. А может это и лишнее.
```bash
[builder@ReposituryRPM ~]$ ll
total 0
[builder@ReposituryRPM ~]$ rpmdev-setuptree
[builder@ReposituryRPM ~]$ ll
total 0
drwxrwxr-x. 7 builder builder 72 Dec  9 11:58 rpmbuild
```

---

Я из будущего провирил.
Достаточно создать adduser builde пользователя и ошибка пропадет. Но дерево каталогов не создается теперь.
Никак. А вот если зайти как builder - то и каталог появляется. 
```
[root@VMforInstallRpm vagrant]# ll
total 1012
-rw-r--r--. 1 root root 1033399 Nov  6 14:19 nginx-1.14.1-1.el7_4.ngx.src.rpm
[root@VMforInstallRpm vagrant]# rpmdev-setuptree
[root@VMforInstallRpm vagrant]# ll
total 1012
-rw-r--r--. 1 root root 1033399 Nov  6 14:19 nginx-1.14.1-1.el7_4.ngx.src.rpm
[root@VMforInstallRpm vagrant]# rpm -i https://nginx.org/packages/centos/7/SRPMS/nginx-1.14.1-1.el7_4.ngx.src.rpm
warning: /var/tmp/rpm-tmp.erofUQ: Header V4 RSA/SHA1 Signature, key ID 7bd9bf62: NOKEY
[root@VMforInstallRpm vagrant]# ll
total 1012
-rw-r--r--. 1 root root 1033399 Nov  6 14:19 nginx-1.14.1-1.el7_4.ngx.src.rpm
[root@VMforInstallRpm vagrant]# 
[root@VMforInstallRpm vagrant]# su - builder
[builder@VMforInstallRpm ~]$ ll
total 0
[builder@VMforInstallRpm ~]$ rpmdev-setuptree
[builder@VMforInstallRpm ~]$ ll
total 0
drwxrwxr-x. 7 builder builder 72 Dec  9 15:12 rpmbuild
[builder@VMforInstallRpm ~]$ ll rpmbuild/SPECS/
total 0
[builder@VMforInstallRpm ~]$ rm -rf rpmbuild/
[builder@VMforInstallRpm ~]$ ll
total 1012
-rw-rw-r--. 1 builder builder 1033399 Nov  6 14:19 nginx-1.14.1-1.el7_4.ngx.src.rpm
[builder@VMforInstallRpm ~]$ rpm -i nginx-1.14.1-1.el7_4.ngx.src.rpm 
warning: nginx-1.14.1-1.el7_4.ngx.src.rpm: Header V4 RSA/SHA1 Signature, key ID 7bd9bf62: NOKEY
[builder@VMforInstallRpm ~]$ ll
total 1012
-rw-rw-r--. 1 builder builder 1033399 Nov  6 14:19 nginx-1.14.1-1.el7_4.ngx.src.rpm
drwxr-xr-x. 4 builder builder      34 Dec  9 15:28 rpmbuild
[builder@VMforInstallRpm ~]$ 
```
После команды rpmdev-setuptree - в дереве пусто.
После удаления rpmbuild и установки не по ссылке, а по скачанному пакету - каталог rpmbuild появился.

**Вопрос: Обязательно делать rpmdev-setuptree под юзером builder? Можно как-то объяснить такое поведение системы при создании дерева каталогов?**

---

Так, тут нет скачанного файла ну и ладно, можно же вроде по ссылке ставить
При установке такого пакета в домашней директории создаетсā древо каталогов длā
сборки:
```bash
rpm -i https://nginx.org/packages/centos/7/SRPMS/nginx-1.14.1-1.el7_4.ngx.src.rpm
```

**Вопрос: В методичке видно, что команда без ошибок выполнилась из под пользователя root, почему у меня тогда возникла ошибка из под root, а под builder - все выполнилось без проблем?**

Зачем-то нужен openssl 
```bash
wget https://www.openssl.org/source/latest.tar.gz
tar -xvf latest.tar.gz
```

Вот что в каталоге сейчас.
```bash
[builder@ReposituryRPM ~]$ ll
total 8160
-rw-rw-r--.  1 builder builder 8350547 Nov 20 14:07 latest.tar.gz
drwxr-xr-x. 19 builder builder    4096 Nov 20 13:35 openssl-1.1.1a
drwxrwxr-x.  7 builder builder      72 Dec  9 11:58 rpmbuild
```

Еще пакет для сборки. Хотя я его под рутом уже ставил.
```bash
sudo yum-builddep rpmbuild/SPECS/nginx.spec
```

**Вопрос: Я не заметил, на каком этапе получилось, что в дереве каталогов `rpmbuild?` появились файлы нужного нам nginx?**

**Ответ: При установке такого пакета в домашней директории создается дерево каталогов для сборки.**

**Вопрос: Видимо, это какой-то специальный пакет для пересборки? Это только у nginx такой есть или и другие пакеты имеет специальную версию для пересборки?**

**Ответ: Видимо, на офф.сайте есть исходники, которые нужно компилировать `SRPMS/` , а есть `x86_64/` - готовые к установке пакеты.**

```
Index of /packages/centos/7/
../
SRPMS/                                             04-Dec-2018 15:31                   -
i386/                                              15-Jul-2014 13:50                   -
noarch/                                            18-Apr-2017 08:24                   -
ppc64le/                                           04-Dec-2018 15:31                   -
x86_64/                                            04-Dec-2018 15:31                   -
```

**Вопрос: Это обязательно, что если в имени файла находится src - это исходники?**

**Вопрос: Некоторые пакеты качаю [тут][3] и есть вариант - Binary Package и Source Package, это как раз и есть, бинакрик - готовый  установке и src - исходники?**

**Вопрос: Я правильно понимаю, что установка src пакета - это вроде распакевки его в rpmbuild со всеми подкаталогами для сборки?**

**Вопрос: Не понятна разница, между пакетами которые нужно устанавливать для пересборки `nginx-1.14.1-1.el7_4.ngx.src.rpm` и пакеты которые нужно распаковывать https://www.openssl.org/source/latest.tar.gz . Это зависит от формата поставки пакетов производителем или от того, какой пакет внутрь какого мы хотим вставить?**

**Вопрос: Это стандарт, что внутри `src` будет структура `BUILD  BUILDROOT  RPMS  SOURCES  SPECS  SRPMS`, 
а внутри `latest.tar.gz` - `ACKNOWLEDGEMENTS  config          crypto    FAQ           libssl.a   NOTES.ANDROID  openssl.pc     test ....` ?** 

```bash
[builder@ReposituryRPM ~]$ ll rpmbuild/SPECS/
total 20
-rw-r--r--. 1 builder builder 18608 Nov  6 14:04 nginx.spec
```
А ведь nginx то не установлен. Какой-то старнный пакет.
```bash
[builder@ReposituryRPM ~]$ rpm -qa | grep nginx
[builder@ReposituryRPM ~]$
```

Вот а параметры внутри rpmbuild/SPECS/nginx.spec вообще не понятные, что тут можно добавлять что нельзя. ([все доступные опции для сборки][2])
```bash
[builder@ReposituryRPM ~]$ diff rpmbuild/SPECS/nginx.spec gistfile1.txt 
110c110
<     --with-debug
---
>     --with-openssl=/root/openssl-1.1.1a
```
Вот разница с тем что сейчас и файлом из примера.

**Вопрос: Если добавить openssl-1.1.1a он появится в зависимостях пакета nginx?**

Сборка. Везде есть какие-то проблемы. 
```bash
rpmbuild -bb rpmbuild/SPECS/nginx.spec
...
checking for OS
 + Linux 3.10.0-862.2.3.el7.x86_64 x86_64
checking for C compiler ... not found

./configure: error: C compiler cc is not found

error: Bad exit status from /var/tmp/rpm-tmp.pYMyeW (%build)


RPM build errors:
    Bad exit status from /var/tmp/rpm-tmp.pYMyeW (%build)
```

Установил это
```bash
sudo yum install gcc
```

Снова ошибка.
```bash
make: *** [build] Error 2
error: Bad exit status from /var/tmp/rpm-tmp.S0uBRn (%build)

```

Нашел расширенный список пакетов для установки
```bash
sudo yum install -y rpmdevtools gcc make wget gd-devel automake yum-utils perl-devel zlib-devel createrepo pcre-devel GeoIP-devel openssl-devel libxslt-devel openldap-devel perl-ExtUtils-Embed 
```
**Вопрос: Каких из вышеперечисленных пакетов не хватало для устранении предыдущей ошибки? Я просто кинул все и что-то помолго, видимо**

Это уже ближе к моим косякам. Путь то не верный! `/root/openssl-1.1.1a: Not a directory`
```bash
cd /root/openssl-1.1.1a \
&& if [ -f Makefile ]; then make clean; fi \
&& ./config --prefix=/root/openssl-1.1.1a/.openssl no-shared no-threads  \
&& make \
&& make install_sw LIBDIR=lib
/bin/sh: line 0: cd: /root/openssl-1.1.1a: Not a directory
make[1]: *** [/root/openssl-1.1.1a/.openssl/include/openssl/ssl.h] Error 1
make[1]: Leaving directory `/home/builder/rpmbuild/BUILD/nginx-1.14.1'
make: *** [build] Error 2
error: Bad exit status from /var/tmp/rpm-tmp.GGJx37 (%build)
```

Что-то наконец-то даже собралось.
```bash
Executing(%clean): /bin/sh -e /var/tmp/rpm-tmp.jBi6Tv
+ umask 022
+ cd /home/builder/rpmbuild/BUILD
+ cd nginx-1.14.1
+ /usr/bin/rm -rf /home/builder/rpmbuild/BUILDROOT/nginx-1.14.1-1.el7_4.ngx.x86_64
+ exit 0
[builder@ReposituryRPM ~]$ ll rpmbuild/RPMS/x86_64/
total 4388
-rw-rw-r--. 1 builder builder 1999472 Dec  9 13:10 nginx-1.14.1-1.el7_4.ngx.x86_64.rpm
-rw-rw-r--. 1 builder builder 2488956 Dec  9 13:10 nginx-debuginfo-1.14.1-1.el7_4.ngx.x86_64.rpm
```

Вот [вариант][4] сборки из исходников еще.

Установка
```bash
sudo yum localinstall -y rpmbuild/RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm
```

```bash
[builder@ReposituryRPM ~]$ systemctl start nginx
==== AUTHENTICATING FOR org.freedesktop.systemd1.manage-units ===
Authentication is required to manage system services or units.
Authenticating as: builder
Password: 
==== AUTHENTICATION COMPLETE ===
[builder@ReposituryRPM ~]$ systemctl status nginx
в—Џ nginx.service - nginx - high performance web server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Sun 2018-12-09 13:54:29 UTC; 7s ago
     Docs: http://nginx.org/en/docs/
  Process: 30511 ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx.conf (code=exited, status=0/SUCCESS)
 Main PID: 30512 (nginx)
   CGroup: /system.slice/nginx.service
           в”њв”Ђ30512 nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx.conf
           в””в”Ђ30513 nginx: worker process

Dec 09 13:54:29 ReposituryRPM systemd[1]: Starting nginx - high performance web server...
Dec 09 13:54:29 ReposituryRPM systemd[1]: PID file /var/run/nginx.pid not readable (yet?) after start.
Dec 09 13:54:29 ReposituryRPM systemd[1]: Started nginx - high performance web server.
[builder@ReposituryRPM ~]$ 
```

---

Задание 2 - репоизиторий

Директория для статики у NGINX поумолчанию /usr/share/nginx/html - для статических страниц что-ли?
```bash
[builder@ReposituryRPM ~]$ sudo mkdir /usr/share/nginx/html/repo
```
Копирование новоскомпилированного пакета.
```bash
[builder@ReposituryRPM ~]$  sudo cp rpmbuild/RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm /usr/share/nginx/html/repo
```

```bash
[root@packages ~]# wget http://www.percona.com/downloads/percona-release/redhat/0.1-6/percona-release-0.1-6.noarch.rpm -O /usr/share/nginx/html/repo/percona-release-0.1-6.noarch.rpm
[builder@ReposituryRPM ~]$ ll /usr/share/nginx/html/repo/
total 1972
-rw-r--r--. 1 root root 1999472 Dec  9 14:08 nginx-1.14.1-1.el7_4.ngx.x86_64.rpm
-rw-r--r--. 1 root root   14520 Jun 13 06:34 percona-release-0.1-6.noarch.rpm
```
Создание репозитория (Я так понимаю, тут создается база данных пакетов repodata и при добавлении пакетов нужно как то обновлять ее. А какая команда для обновления?)
```bash
[builder@ReposituryRPM ~]$  createrepo /usr/share/nginx/html/repo/
Directory /usr/share/nginx/html/repo/ must be writable.
[builder@ReposituryRPM ~]$ sudo  createrepo /usr/share/nginx/html/repo/
Spawning worker 0 with 2 pkgs
Workers Finished
Saving Primary metadata
Saving file lists metadata
Saving other metadata
Generating sqlite DBs
Sqlite DBs complete
[builder@ReposituryRPM ~]$ 
```

поправить конфигурационный файл /etc/nginx/conf.d/default.conf
```bash
    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
        autoindex on;
    }
```

Проверка конфигурационного файла на наличие синтаксических ошибок. Перезагрузка.
```bash
   76  sudo nginx -t
   77  sudo nginx -s reload
```

Вот что по адресу http://192.168.33.12/repo/
```bash
Index of /repo/
../
repodata/                                          09-Dec-2018 14:15                   -
nginx-1.14.1-1.el7_4.ngx.x86_64.rpm                09-Dec-2018 14:08             1999472
percona-release-0.1-6.noarch.rpm                   13-Jun-2018 06:34               14520
```

---

Задание 2.1 - Все вышеперечисленное в Vagrant
По сути ведь нужно просто накопировать команды?

Если так то задача не простая. Безусловно есть перечень команд, которые просто какопировать в shell и еще поправить конфиги sed-ом.
Но, проблема с тем, что нужно создавать пользователя и только из под него все делать, создает массу трудностей. 
Постоянно использовать sudo и пароль. Это интерактив, который просто так не накопируешь. Или править `sudoers` 

Позволяет не спрашивать пароль пользователя для sudo команд
```bash
%wheel  ALL=NOPASSWD: ALL
```

Вобщем, пока вопрос открытый. Vagrant не реагирует на команду смены пользователя.
```bash
    rpmcreatedandrepo: Adding user builder to group wheel
    rpmcreatedandrepo: root
    rpmcreatedandrepo: root
```
Так Vagrant реагирует на команды
```bash
        whoami
        sudo su - builder # Тут пароль не нужен
        #rpmdev-setuptree
        whoami
```
**Вопрос: Почему Vagrant не реагирует на команду смены пользователя?**

Если просто загрузить машину и накопировать туда комманд следующих - все работает. Но не в Vagrantfile.
Видимо уже не залаботает. Видимо я уже запутался, что я делаю командами sudo и там пути ведут в root, а что и под пользователя.
Не работает что-то.
```bash
[builder@rpmcreatedandrepo ~]$ rpmbuild -bb rpmbuild/SPECS/nginx.spec
error: failed to stat /home/builder/rpmbuild/SPECS/nginx.spec: No such file or directory
```

```bash
        yum install -y mdadm  smartmontools  hdparm  gdisk  redhat-lsb-core  wget  rpm-build  yum-utils  gcc  rpmdevtools  make gd-devel  automake  perl-devel  zlib-devel  createrepo  pcre-devel  GeoIP-devel  openssl-devel e2fsprogs lvm2 xfsdump epel-release
        sudo sed -i 's/%wheel\s*ALL=(ALL)\s*ALL/%wheel  ALL=NOPASSWD: ALL/g' /etc/sudoers
        adduser builder
        gpasswd -a builder wheel
        whoami
        sudo su - builder # Тут пароль не нужен
        #rpmdev-setuptree # Не нужна команда
        whoami
        wget https://nginx.org/packages/centos/7/SRPMS/nginx-1.14.1-1.el7_4.ngx.src.rpm
        sudo rpm -i nginx-1.14.1-1.el7_4.ngx.src.rpm
        sudo wget https://www.openssl.org/source/latest.tar.gz
        sudo tar -xvf latest.tar.gz
        sudo yum-builddep rpmbuild/SPECS/nginx.spec
        sudo sed -i 's/.*--with-debug/    --with-openssl=\/home\/builder\/openssl-1.1.1a/g' /root/rpmbuild/SPECS/nginx.spec
        sudo rpmbuild -bb rpmbuild/SPECS/nginx.spec
        sudo yum localinstall -y /root/rpmbuild/RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm
        sudo systemctl start nginx
        sudo mkdir /usr/share/nginx/html/repo
        sudo cp /root/rpmbuild/RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm /usr/share/nginx/html/repo/
        sudo wget http://www.percona.com/downloads/percona-release/redhat/0.1-6/percona-release-0.1-6.noarch.rpm -O /usr/share/nginx/html/repo/percona-release-0.1-6.noarch.rpm
        sudo wget http://www.percona.com/downloads/percona-release/redhat/0.1-6/percona-release-0.1-6.noarch.rpm -O /usr/share/nginx/html/repo/percona-release-0.1-6.noarch.rpm # Странно, но на одну команду может и ошибку выдать.
        sudo createrepo /usr/share/nginx/html/repo/
        sudo sed -i 's/index  index.html index.htm;/index  index.html index.htm;\n        autoindex on;/' /etc/nginx/conf.d/default.conf
        sudo nginx -t
        sudo nginx -s reload
        sudo curl -a http://localhost/repo/
```

Видимо сначала нужно решить вопрос из под какого пользователя все делать. Либо выпутаться и верно обращаться с путями.

---

Лирическое отступление, пару дней назад пришлось экстренно поднимать репозиторий, и воспользовался другим методом.
Я и так-то его раньше не ставил, поэтому все методы в новинку.

Скачать iso centos нужной версии и релиза с [зеркала][5].
Образ примонтировать.
Накопировать из примонтированной директории Packages и 
Расшарить эту директорию с помощью httpd. Там в конфиге указать диреторию и Alias - url нашего новго репозитория.
Тут могут быть ососбенности, новый конфиг класть или добавить в текущий, какие Alias должны быть, на каком порту все это.




**Вопрос: ?**
**Вопрос: ?**


---

[1]: https://otus.ru/media/1d/a6/%D0%9F%D1%80%D0%B0%D0%BA%D1%82%D0%B8%D0%BA%D0%B0_%D0%A3%D0%BF%D1%80%D0%B0%D0%B2%D0%BB%D0%B5%D0%BD%D0%B8%D0%B5_%D0%BF%D0%B0%D0%BA%D0%B5%D1%82%D0%B0%D0%BC%D0%B8-5373-1da674.pdf
[2]: https://nginx.org/ru/docs/configure.html
[3]: https://centos.pkgs.org/7/epel-x86_64/nginx-1.12.2-2.el7.x86_64.rpm.html
[4]: https://blog.hook.sh/adm/nginx-compile-from-sources/
[5]: http://mirror.centos.org/centos/