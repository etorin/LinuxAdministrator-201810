### PAM

#### Задание 1.
Запретить всем пользователям, кроме группы admin логин в выходные и праздничные дни

Сначала я подумал, что не работает из за неверного времени.
Что-то из этого помогло
```bash
    2  date
    3  ntpdate -qu 1.ro.pool.ntp.org
    4  yum  install ntpdate
    5  ntpdate -qu 1.ro.pool.ntp.org
    6  date
    7  timedatectl set-ntp true
    8  timedatectl status 
    9  cd /usr/share/zoneinfo
   10  tzselect
   11  date
   12  ntpdate -qu 1.ro.pool.ntp.org
   13  timedatectl set-ntp true
   14  timedatectl status 
   15  systemctl enable ntpd
   16  yum install ntp
   17  systemctl enable ntpd
   18  vi /etc/ntp.conf
   19  /etc/init.d/ntpd restart
   20  systemctl restart ntpd
   21  date
   22  /usr/sbin/ntpdate pool.ntp.org
   23  systemctl stop ntpd
   24  /usr/sbin/ntpdate pool.ntp.org
   25  date
   26  cd /usr/share/zoneinfo
   27  tzselect
   28  date
   29  systemctl start ntpd
   30  date
   31  cat /etc/timezone
   32  cat  /etc/localtime
   33  cat /etc/ntp.conf | grep zone
   34  ntpdate otherntp.research.gov
   35  ntpq -p
   36  date
   37  rm -rf /etc/localtime
   38  ln -s /usr/share/zoneinfo/Europe/Moscow /etc/localtime
   39  date
   40  systemctl restart ntpd
   41  ntpq -p
   42  date
```

С чего хотелось бы начать.
Я не нашел ни одной вменяемой статьи про настройку pam.
Да, есть описания, что значат `required sufficient optional`
https://www.ibm.com/developerworks/ru/library/l-pam/index.html
Что есть модули pam_time например.
Понятно что проверка отработки модулей осуществляется последовательно, но
черт возьми, в каких сочетаниях я могу все это использовать, и почему модуль `pam_time` должен быть в `account` и стоять после 	`pam_unix.so` а не после стоявщего там по-умолчанию другого модуля...
Короче, так не работает проверка времени логина
```bash
account    required     pam_nologin.so
account    include      system-auth
account    required     pam_time.so
```
А так работает.
```bash
account    required     pam_unix.so
account    required     pam_time.so
```

**Вопрос: Есть какое-то понятное и развернутое описание той логики, по которой все это работае, и в каких сочетаниях(account/auth...) (required sufficient optional) и типы модулей приемлемы/работаю, а какие нет?**

В книжке идет описание модулей и указание - где их использовать нужно (session/auth/account)
https://books.google.ru/books?id=HHmRvJ829QkC&pg=PA47&lpg=PA47&dq=pam_time+usergroup+instead+username&source=bl&ots=5ti-yJttWw&sig=29SMlsk-ryNBXjUTm9H7joTg-5Y&hl=ru&sa=X&ved=2ahUKEwjg5aXBlu_eAhULpYsKHUcaCt4Q6AEwB3oECAUQAQ#v=onepage&q=pam_time%20usergroup%20instead%20username&f=false

Так. Теперь pam обращается к конфигурационному файлу /etc/security/time.conf
Это разрешающее правило.
Оно разрешает входить пользователю vagrant все дни недели с 08:00-09:30
```bash
sshd ; * ; vagrant; Al0800-0930
```
Сейчас 10:00 воскресенья, и vagrant не попадает. А root без проблем.

Кроме выходных (не праздничных, наверное)
```bash
sshd ; * ; vagrant; Wk0000-2400
#или
#sshd ; * ; vagrant; !Wd0000-2400
```
Допустимые значения дней
**Вопрос: Не понимаю, как исключить праздничные дни и должно ли входить в список выходных дней 7ое ноября?**
https://linux.die.net/man/5/time.conf
Mo Tu We Th Fr Sa Su Wk Wd Al

Следующий шаг - группа пользователей
https://www.techrepublic.com/article/using-pam-to-restrict-access-based-on-time/
И тут пустота.
Куча потраченного времени. Результатов нет. Грыппы в конфиг time не вставить.
Самая бредовая идея - вставить скрипт при auth и менять строку в конфиге time - выгребая чере | всех пользователей группы

Меня направили в сторону модуля pam_script.so

Написал bash скрипт с переменной PAM_USER, описал зависимости от дней и групп. 
Если PAM_USER  определить вручную, скрипт возвращает сообщение и exit 0 или 1 в зависимости от результата проверки.
get_holiday_sed.sh и файл holidays с датами формата 01.01 чере перенос строки.

Осталось добавить модулб в конфиг и понеслось.

Оставил в файлах по одной стороке auth - ничего.
/etc/pam.d/sshd
/etc/pam.d/login
```bash
auth       required     pam_script.so runas=root onauth="/etc/pam.d/pam_script/get_holiday.sh"
```

Поставил первой строкой эту (в session секйии) - ничего. Успешный логин. Но если допускаю ошибку - все ломается, никого не пускает.
```bash
session    required     pam_script.so runas=root onsessionopen="/etc/pam.d/pam_script/get_holiday.sh"
```

Есть показатель запуска который не сработал ни разу - файлов нет.
```bash
touch /home/vagrant/file-`date +%H-%m-%S`
```

Итого, попросив помощи преподавателя, обнаружилось следующее.
1. Не работает в скрипте это, видимо не хватает прав.
```bash
touch /home/vagrant/file-`date +%H-%m-%S`
```
Заработало так. 
```bash
touch /tmp/file-`date +%H-%m-%S`
# На удивление права у файлов root
[root@bashscripts vagrant]# ll /tmp/
total 4
-rw-r--r--. 1 root    root      0 Nov 28 07:53 file-07-11-01
-rw-r--r--. 1 root    root      0 Nov 28 07:53 file-07-11-21
```

2. Тот метод `pam_script.so runas=root onsessionopen=` не заработал.
**Вопрос: Что было сделано не так в методе с явным указание скрипта?**

3. Нужно переписать файл /etc/pam_script своим скриптом

4. Мой скрипт в идентичной конфигурации не заработал.
Исправляю скрипт.

!!! Замечание.
Добавил в vagrantfile строку
```bash
yum install -y pam-script
```
Но файла `/etc/pam_script` не появилось, когда проверял созданную машиную. Пришлось руками. 
```bash
Installed:
  pam_script.x86_64 0:1.1.8-1.el7                                                                                 

Complete!
```

Вставляю строку `auth       required     pam_script.so` в конец `/etc/pam.d/sshd`
И перестает работать любой логин/пароль.
А прошлый раз работало. И что изменилось? Какой-то капризный pam.

Ошибка это была или нет
```bash
yum install -y pam-script
# А надо так
yum install -y pam_script
```

Переписал файл /etc/pam_script своим и опять не работает.
Удаляю машину и создаю снова. Скипр исходный не сохранил.

Я грешу на переносы строк windows при копировании.
На самом деле скрипт работает и что то даже делает, но править я его уже не хочу, ибо кучу времени уже потратил чтоб ничего не понять.
Тут дату можно grep из файла вместо цикла. Потому что нет условия прохождения всего цикла.
```bash
vagrant Hello!
Strat 05-12-43
05-12-43 You are vagrant, lets check you
05-12-43 [vagrant] try to check user user1
05-12-43 [vagrant] You are out of list. Sorry
05-12-43 [vagrant] try to check user vagrant
05-12-43 [vagrant] you are vagrant, lets check date
05-12-43 [vagrant] you are vagrant, date 01.01 to check
05-12-43 [vagrant] Lets work!
```
К слову о моей эффективности
Otus. Администратор Linux.HW7 task1 14:23:15

---

2. Дать конкретному пользователю права рута
Первый и самый очевидный вариант visudo
```bash
[user1@bashscripts ~]$ sudo -s
[sudo] password for user1: 
[root@bashscripts user1]# 
```
Вместо
```bash
[user1@bashscripts ~]$ sudo -s
user1 is not in the sudoers file.  This incident will be reported.
```

Еще сделал как в чате писали
https://unix.stackexchange.com/questions/454708/how-do-you-add-cap-sys-admin-permissions-to-user-in-centos-7
Файла изначально не существовало, я думал модуль не установлен, но просто создание файла сработало.
```bash
[root@bashscripts vagrant]# vi /etc/security/capability.conf
cap_sys_admin  vagrant
cap_sys_admin  user1
none *
```
В других файлах pam нет pam_rootok.so поэтому добавил только сюда
```bash
[root@bashscripts vagrant]# vi /etc/pam.d/su
#%PAM-1.0
auth            required        pam_cap.so
auth            sufficient      pam_rootok.so
```
В данном случае для повышения привилегий нужно вводить такую команду `su - user1`
```bash
[user1@bashscripts ~]$ su - user1
Password: 
Last login: Wed Dec  5 06:48:44 UTC 2018 from 192.168.33.1 on pts/2
[user1@bashscripts ~]$ capsh --print
Current: = cap_sys_admin+i
Bounding set =cap_chown,cap_dac_override,cap_dac_read_search,cap_fowner,cap_fsetid,cap_kill,cap_setgid,cap_setuid,cap_setpcap,cap_linux_immutable,cap_net_bind_service,cap_net_broadcast,cap_net_admin,cap_net_raw,cap_ipc_lock,cap_ipc_owner,cap_sys_module,cap_sys_rawio,cap_sys_chroot,cap_sys_ptrace,cap_sys_pacct,cap_sys_admin,cap_sys_boot,cap_sys_nice,cap_sys_resource,cap_sys_time,cap_sys_tty_config,cap_mknod,cap_lease,cap_audit_write,cap_audit_control,cap_setfcap,cap_mac_override,cap_mac_admin,cap_syslog,35,36
Securebits: 00/0x0/1'b0
 secure-noroot: no (unlocked)
 secure-no-suid-fixup: no (unlocked)
 secure-keep-caps: no (unlocked)
uid=1001(user1)
gid=1001(user1)
groups=1001(user1),1002(admin)
```
Я полагаю, что тут есть какие-то преднастроенные шаблоны и кроме cap_sys_admin
http://rflinux.blogspot.com/2014/06/linux-perusr-caps.html
http://fliplinux.com/12675.html

Но вот незадача
```bash
[user1@bashscripts ~]$ capsh --print
Current: =
...

[user1@bashscripts ~]$ cat /etc/shadow
cat: /etc/shadow: Permission denied

[user1@bashscripts ~]$ su - user1
Current: = cap_sys_admin+i

[user1@bashscripts ~]$ cat /etc/shadow
cat: /etc/shadow: Permission denied
```
У меня как не было повышенных прав так и нет.

```bash
[user1@bashscripts ~]$ sudo cat /etc/shadow
[sudo] password for user1: 
user1 is not in the sudoers file.  This incident will be reported.
```
**Вопрос: Что означает Current: = cap_sys_admin+i а главное, что это мне дает если на права все равно система ругается?**

Как и коллега в чате сказал, не получается сделать так, чтоб не вводить su -
Такой вариант не помог 
```bash
[root@bashscripts vagrant]# vi /etc/pam.d/login 
#%PAM-1.0
auth       required     pam_cap.so
```
http://manpages.ubuntu.com/manpages/xenial/man8/pam_cap.8.html
А файла /etc/pam.d/common-auth вообще нет

Попробовал вместо `auth       required     pam_cap.so` вначале добавить пользователя по аналогии с vagrant
```bash
account         sufficient      pam_succeed_if.so uid = 0 use_uid quiet
account         sufficient      pam_succeed_if.so user = user1 use_uid quiet
account         [success=1 default=ignore] \
                                pam_succeed_if.so user = vagrant use_uid quiet
account         required        pam_succeed_if.so user notin root:vagrant:user1
```
Результата нет
```bash
[user1@bashscripts ~]$ su - user1
Password: 
Last login: Wed Dec  5 07:25:30 UTC 2018 from 192.168.33.1 on pts/2
[user1@bashscripts ~]$ capsh --print
Current: =
```
**Вопрос: Что я сделал не так?**

По итогу, я так и не понял, как vagrant получает из коробки права root.
Единственное что делается - Vagrantfile
```bash
        mkdir -p ~root/.ssh
              cp ~vagrant/.ssh/auth* ~root/.ssh
```

Но файла auth* для копирования в директории user1 нет
```bash
[root@bashscripts vagrant]# cp ~user1/.ssh/auth* ~root/.ssh       
cp: cannot stat вЂ/home/user1/.ssh/auth*вЂ™: No such file or directory
        
[root@bashscripts vagrant]# cp ~user1/
.bash_history  .bash_logout   .bash_profile  .bashrc        y              y.pub          

[root@bashscripts vagrant]# cp ~vagrant/
.bash_history  .bash_profile  pam_script     pam.sh         
.bash_logout   .bashrc        pam_script_or  .ssh/          
```
**Вопрос: Объясните как vagrant из коробки получает рутовые права (где и что нужно прописать) и почему не получилось то же самое сделать для user1?**

Как обычно, по запросу могу предоставить лог действий.

Otus. Администратор Linux.HW7t2
1:17:37

Что еще интересного? (нет времени проверять уже, 15 дней домашки не сдавал)
#### Добавление третьего фактора 
https://www.8host.com/blog/nastrojka-mnogofaktornoj-autentifikacii-ssh-na-centos-7/

#### Собственный модуль PAM
https://www.opennet.ru/base/net/pam_linux.txt.html