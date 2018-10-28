### Дисковая подсистема

Накопировал Vagrantfile рекомендованный.

Добавил команду чтоб получилось по ssh ходить.

```ruby
           sed -i '65s/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
           systemctl restart sshd
```

И сразу ошибка при загрузке vm.
```bash
    otuslinux: Could not retrieve mirrorlist http://mirrorlist.centos.org/?release=7&arch=x86_64&repo=os&infra=vag error was
    otuslinux: 14: HTTP Error 403 - Forbidden
```

С сетью все хорошо
```bash
[root@otuslinux vagping 8.8.8.8 -c1
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=118 time=13.0 ms

--- 8.8.8.8 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 13.012/13.012/13.012/0.000 ms
[root@otuslinux vagrant]# ping ya.ru -c1
PING ya.ru (87.250.250.242) 56(84) bytes of data.
64 bytes from ya.ru (87.250.250.242): icmp_seq=1 ttl=53 time=14.5 ms

--- ya.ru ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 14.536/14.536/14.536/0.000 ms
```

Сайт даже что-то отдает
```bash
[root@otuslinux vagrant]# curl http://mirrorlist.centos.org/?release=7
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
```

Кто-то говорит - selinux отключить - не помогло.
```bash
[root@otuslinux vagrant]# /usr/sbin/sestatus
SELinux status:                 disabled
```

Но вот так все пока что.
```bash
[root@otuslinux vagrant]# yum makecache
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
Could not retrieve mirrorlist http://mirrorlist.centos.org/?release=7&arch=x86_64&repo=addons error was
14: HTTP Error 403 - Forbidden
```

Странно что и в браузере по ссылке
`http://mirrorlist.centos.org/?release=7&arch=x86_64&repo=addons`
получаю
```bash
Invalid release/repo/arch combination
```

От отчаяния, мало ли что изменилось, я поменял IP на тот, с которым у меня когда то все было хорошо, в надежде на чудо.
Чуда не произошло.
При загрузке - та же ошибка.

Вот что я делал дальше. Просто так. Не знаю зачем.
```bash
[vagrant@otuslinux ~]$ yum repolist
Loaded plugins: fastestmirror
Determining fastest mirrors
Could not retrieve mirrorlist http://mirrorlist.centos.org/?release=7&arch=x86_64&repo=os&infra=vag error was
14: HTTP Error 403 - Forbidden
Loading mirror speeds from cached hostfile
Loading mirror speeds from cached hostfile
Loading mirror speeds from cached hostfile
repo id                                                        repo name                                                        status
base/7/x86_64                                                  CentOS-7 - Base                                                  0
extras/7/x86_64                                                CentOS-7 - Extras                                                0
updates/7/x86_64                                               CentOS-7 - Updates                                               0
repolist: 0
[vagrant@otuslinux ~]$ yum makecache
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: dedic.sh
 * extras: mirror.corbina.net
 * updates: mirror.corbina.net
base                                                                                                           | 3.6 kB  00:00:00     
extras                                                                                                         | 3.4 kB  00:00:00     
updates                                                                                                        | 3.4 kB  00:00:00     
(1/12): base/7/x86_64/group_gz                                                                                 | 166 kB  00:00:00     
(2/12): extras/7/x86_64/filelists_db                                                                           | 603 kB  00:00:01     
(3/12): extras/7/x86_64/prestodelta                                                                            | 100 kB  00:00:00     
(4/12): extras/7/x86_64/primary_db                                                                             | 204 kB  00:00:00     
(5/12): extras/7/x86_64/other_db                                                                               | 126 kB  00:00:00     
(6/12): updates/7/x86_64/prestodelta                                                                           | 672 kB  00:00:02     
(7/12): base/7/x86_64/other_db                                                                                 | 2.5 MB  00:00:05     
(8/12): updates/7/x86_64/other_db                                                                              | 574 kB  00:00:01     
(9/12): updates/7/x86_64/filelists_db                                                                          | 3.3 MB  00:00:06     
(10/12): base/7/x86_64/filelists_db                                                                            | 6.9 MB  00:00:07     
(11/12): base/7/x86_64/primary_db                                                                              | 5.9 MB  00:00:08     
(12/12): updates/7/x86_64/primary_db                                                                           | 6.0 MB  00:00:05     
Metadata Cache Created
```

```bash
[vagrant@otuslinux ~]$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 52:54:00:c0:42:d5 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global noprefixroute dynamic eth0
       valid_lft 85853sec preferred_lft 85853sec
    inet6 fe80::5054:ff:fec0:42d5/64 scope link 
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:b9:45:a8 brd ff:ff:ff:ff:ff:ff
    inet 192.168.33.12/24 brd 192.168.33.255 scope global noprefixroute eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:feb9:45a8/64 scope link 
       valid_lft forever preferred_lft forever
```

```bash
[vagrant@otuslinux ~]$ sudo yum install -y mdadm smartmontools hdparm gdisk
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
Could not retrieve mirrorlist http://mirrorlist.centos.org/?release=7&arch=x86_64&repo=os&infra=vag error was
14: HTTP Error 403 - Forbidden


 One of the configured repositories failed (Unknown),
 and yum doesn't have enough cached data to continue. At this point the only
 safe thing yum can do is fail. There are a few ways to work "fix" this:

     1. Contact the upstream for the repository and get them to fix the problem.

     2. Reconfigure the baseurl/etc. for the repository, to point to a working
        upstream. This is most often useful if you are using a newer
        distribution release than is supported by the repository (and the
        packages for the previous distribution release still work).

     3. Run the command with the repository temporarily disabled
            yum --disablerepo=<repoid> ...

     4. Disable the repository permanently, so yum won't use it by default. Yum
        will then just ignore the repository until you permanently enable it
        again or use --enablerepo for temporary usage:

            yum-config-manager --disable <repoid>
        or
            subscription-manager repos --disable=<repoid>

     5. Configure the failing repository to be skipped, if it is unavailable.
        Note that yum will try to contact the repo. when it runs most commands,
        so will have to try and fail each time (and thus. yum will be be much
        slower). If it is a very temporary problem though, this is often a nice
        compromise:

            yum-config-manager --save --setopt=<repoid>.skip_if_unavailable=true

Cannot find a valid baseurl for repo: base/7/x86_64

```

```bash
[vagrant@otuslinux ~]$ yum repolist
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirror.sale-dedic.com
 * extras: mirror.reconn.ru
 * updates: mirror.corbina.net
repo id                                                        repo name                                                        status
base/7/x86_64                                                  CentOS-7 - Base                                                  9,911
extras/7/x86_64                                                CentOS-7 - Extras                                                  432
updates/7/x86_64                                               CentOS-7 - Updates                                               1,589
repolist: 11,932
```

```bash
[vagrant@otuslinux ~]$ yum makecache
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: dedic.sh
 * extras: mirror.reconn.ru
 * updates: dedic.sh
base                                                                                                           | 3.6 kB  00:00:00     
extras                                                                                                         | 3.4 kB  00:00:00     
updates                                                                                                        | 3.4 kB  00:00:00     
Metadata Cache Created
```

```bash
[vagrant@otuslinux ~]$ sudo yum install -y mdadm smartmontools hdparm gdisk
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: dedic.sh
 * extras: mirror.yandex.ru
 * updates: dedic.sh
base                                                                                                           | 3.6 kB  00:00:00     
extras                                                                                                         | 3.4 kB  00:00:00     
updates                                                                                                        | 3.4 kB  00:00:00     
(1/4): base/7/x86_64/group_gz                                                                                  | 166 kB  00:00:00     
(2/4): extras/7/x86_64/primary_db                                                                              | 204 kB  00:00:00     
(3/4): base/7/x86_64/primary_db                                                                                | 5.9 MB  00:00:04     
(4/4): updates/7/x86_64/primary_db                                                                             | 6.0 MB  00:00:04     
Resolving Dependencies
--> Running transaction check
---> Package gdisk.x86_64 0:0.8.6-5.el7 will be installed
---> Package hdparm.x86_64 0:9.43-5.el7 will be installed
---> Package mdadm.x86_64 0:4.0-13.el7 will be installed
--> Processing Dependency: libreport-filesystem for package: mdadm-4.0-13.el7.x86_64
---> Package smartmontools.x86_64 1:6.5-1.el7 will be installed
--> Processing Dependency: mailx for package: 1:smartmontools-6.5-1.el7.x86_64
--> Running transaction check
---> Package libreport-filesystem.x86_64 0:2.1.11-40.el7.centos will be installed
---> Package mailx.x86_64 0:12.5-19.el7 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

======================================================================================================================================
 Package                                Arch                     Version                                 Repository              Size
======================================================================================================================================
Installing:
 gdisk                                  x86_64                   0.8.6-5.el7                             base                   187 k
 hdparm                                 x86_64                   9.43-5.el7                              base                    83 k
 mdadm                                  x86_64                   4.0-13.el7                              base                   431 k
 smartmontools                          x86_64                   1:6.5-1.el7                             base                   460 k
Installing for dependencies:
 libreport-filesystem                   x86_64                   2.1.11-40.el7.centos                    base                    39 k
 mailx                                  x86_64                   12.5-19.el7                             base                   245 k

Transaction Summary
======================================================================================================================================
Install  4 Packages (+2 Dependent packages)

Total download size: 1.4 M
Installed size: 4.0 M
Downloading packages:
warning: /var/cache/yum/x86_64/7/base/packages/gdisk-0.8.6-5.el7.x86_64.rpm: Header V3 RSA/SHA256 Signature, key ID f4a80eb5: NOKEYTA 
Public key for gdisk-0.8.6-5.el7.x86_64.rpm is not installed
(1/6): gdisk-0.8.6-5.el7.x86_64.rpm                                                                            | 187 kB  00:00:00     
(2/6): libreport-filesystem-2.1.11-40.el7.centos.x86_64.rpm                                                    |  39 kB  00:00:00     
(3/6): hdparm-9.43-5.el7.x86_64.rpm                                                                            |  83 kB  00:00:00     
(4/6): mailx-12.5-19.el7.x86_64.rpm                                                                            | 245 kB  00:00:00     
(5/6): smartmontools-6.5-1.el7.x86_64.rpm                                                                      | 460 kB  00:00:00     
(6/6): mdadm-4.0-13.el7.x86_64.rpm                                                                             | 431 kB  00:00:00     
--------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                 1.5 MB/s | 1.4 MB  00:00:00     
Retrieving key from file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
Importing GPG key 0xF4A80EB5:
 Userid     : "CentOS-7 Key (CentOS 7 Official Signing Key) <security@centos.org>"
 Fingerprint: 6341 ab27 53d7 8a78 a7c2 7bb1 24c6 a8a7 f4a8 0eb5
 Package    : centos-release-7-5.1804.4.el7.centos.x86_64 (@koji-override-1)
 From       : /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : libreport-filesystem-2.1.11-40.el7.centos.x86_64                                                                   1/6 
  Installing : mailx-12.5-19.el7.x86_64                                                                                           2/6 
  Installing : 1:smartmontools-6.5-1.el7.x86_64                                                                                   3/6 
  Installing : mdadm-4.0-13.el7.x86_64                                                                                            4/6 
  Installing : hdparm-9.43-5.el7.x86_64                                                                                           5/6 
  Installing : gdisk-0.8.6-5.el7.x86_64                                                                                           6/6 
  Verifying  : gdisk-0.8.6-5.el7.x86_64                                                                                           1/6 
  Verifying  : 1:smartmontools-6.5-1.el7.x86_64                                                                                   2/6 
  Verifying  : mdadm-4.0-13.el7.x86_64                                                                                            3/6 
  Verifying  : mailx-12.5-19.el7.x86_64                                                                                           4/6 
  Verifying  : hdparm-9.43-5.el7.x86_64                                                                                           5/6 
  Verifying  : libreport-filesystem-2.1.11-40.el7.centos.x86_64                                                                   6/6 

Installed:
  gdisk.x86_64 0:0.8.6-5.el7      hdparm.x86_64 0:9.43-5.el7      mdadm.x86_64 0:4.0-13.el7      smartmontools.x86_64 1:6.5-1.el7     

Dependency Installed:
  libreport-filesystem.x86_64 0:2.1.11-40.el7.centos                            mailx.x86_64 0:12.5-19.el7                           

Complete!
```
Я не представляю, что тут произошло и какое действие привело к положительному результату.
Если кто-то понял, дайте знать, пожалуйста.

Как бы глобальную проблему это не решает. Из коробки это не заработает. Или заработает? Можно же эти команды в vagrantfile накопировать.
Помогло добавление в секцию `SHELL` команды `yum makecache`

**Вопрос: Почему в первой попытке не удалось установить пакет, а после makecache все хорошо?**

Добавил диск 5. Копировать - вставить - поменять 4 на 5, не забыть запятую.
На будущее, не плохо бы разобраться с понаписанным в Vagrentfile, ибо далеко не все очевидно.

```bash
[vagrant@otuslinux ~]$ lsscsi
[0:0:0:0]    disk    ATA      VBOX HARDDISK    1.0   /dev/sda 
[3:0:0:0]    disk    ATA      VBOX HARDDISK    1.0   /dev/sdb 
[4:0:0:0]    disk    ATA      VBOX HARDDISK    1.0   /dev/sdc 
[5:0:0:0]    disk    ATA      VBOX HARDDISK    1.0   /dev/sdd 
[6:0:0:0]    disk    ATA      VBOX HARDDISK    1.0   /dev/sde 
[7:0:0:0]    disk    ATA      VBOX HARDDISK    1.0   /dev/sdf
```

1. **Вопрос: Я, видимо не понял, что значит занулить суперблоки и зачем это нужно и что может быть если не сделать этого?**
2. **Вопрос: Результат такой, это вроде как обнаружено новое устройсво?**
```bash
[vagrant@otuslinux ~]$ sudo mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}
mdadm: Unrecognised md component device - /dev/sdb
mdadm: Unrecognised md component device - /dev/sdc
mdadm: Unrecognised md component device - /dev/sdd
mdadm: Unrecognised md component device - /dev/sde
mdadm: Unrecognised md component device - /dev/sdf
```

Создание raid 10
```bash
[vagrant@otuslinux ~]$ sudo mdadm --create --verbose /dev/md0 -l 10 -n 5 /dev/sd{b,c,d,e,f}
```
Проверка
```bash
[vagrant@otuslinux ~]$ cat /proc/mdstat
Personalities : [raid10] 
md0 : active raid10 sdf[4] sde[3] sdd[2] sdc[1] sdb[0]
      634880 blocks super 1.2 512K chunks 2 near-copies [5/5] [UUUUU]
```
Конфиг для сбора при загрузке
Хочу понять, что нужно положить в файл
```bash
[root@otuslinux vagrant]# mdadm --detail --scan --verbose
ARRAY /dev/md0 level=raid10 num-devices=5 metadata=1.2 name=otuslinux:0 UUID=d8eab7c2:c679a5b5:3f09de33:67fee222
   devices=/dev/sdb,/dev/sdc,/dev/sdd,/dev/sde,/dev/sdf
```
```bash
[root@otuslinux vagrant]#  mdadm --detail --scan --verbose | awk '/ARRAY/ {print}'
ARRAY /dev/md0 level=raid10 num-devices=5 metadata=1.2 name=otuslinux:0 UUID=d8eab7c2:c679a5b5:3f09de33:67fee222
```
```bash
[root@otuslinux vagrant]# mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
```

Так выглядит файл для загрузки параметров raid.

**Вопрос: Почему не нужны данные о дисках devices=/dev/sdb,/dev/sdc,/dev/sdd,/dev/sde,/dev/sdf ???**

**Вопрос: Что такое UUID ?**

**Вопрос: Зачем ключевая фраза `DEVICE partitions` ?**
```bash
[root@otuslinux vagrant]# cat /etc/mdadm/mdadm.conf 
DEVICE partitions
ARRAY /dev/md0 level=raid10 num-devices=5 metadata=1.2 name=otuslinux:0 UUID=d8eab7c2:c679a5b5:3f09de33:67fee222
```
И правда, после перезагрузки ничего не пропало. Хорошо.

Ломаю. `mdadm /dev/md0 --remove /dev/sde`

После поломки:
```bash
    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       -       0        0        3      removed
       4       8       80        4      active sync   /dev/sdf

       3       8       64        -      faulty   /dev/sde
```

И после перезагрузки ничего не вернулось. Почему? Чем плох конфигурационный файл? Или он не восстанавливает 'сломанный' диск?

Тут тоже пусто:
```bash
[root@otuslinux vagrant]# cat /proc/mdstat
Personalities : [raid10] 
md0 : active raid10 sdf[4] sdd[2] sdc[1] sdb[0]
      634880 blocks super 1.2 512K chunks 2 near-copies [5/4] [UUU_U]
      
unused devices: <none>
```
Того что нет удалить нельзя, по всей видимости:

**Вопрос: куда делся sde? 
В конце, когда я так же вызывал fail диска, `cat /proc/mdstat` выдавала `sde[5](F)`**

**Ответ: я и правда не сделал `--fail /dev/sde`, а место этого сделал `remove`**

Закончив домашнюю работу и вернувшись к этому месту снова, я увидел, что система ругалась на отсутствовавшее устройство!
```bash
[root@otuslinux vagrant]# mdadm /dev/md0 --remove /dev/sde
mdadm: hot remove failed for /dev/sde: No such device or address
```
Поэтому не `sde`
```bash
[root@otuslinux vagrant]# cat /proc/mdstat
Personalities : [raid10] 
md0 : active raid10 sdf[4] sdd[2] sdc[1] sdb[0]
      634880 blocks super 1.2 512K chunks 2 near-copies [5/4] [UUU_U]
      
unused devices: <none>
```
```bash
[root@otuslinux vagrant]# mdadm /dev/md0 --add /dev/sde
mdadm: added /dev/sde
[root@otuslinux vagrant]# 
```
После чего машина была отправлена в сон, ибо свободное время подошло к концу и нужно идти на работу.

Вечером продолжил.
После пробуждения машины - ничего удивительного. Все диски в строю.
```bash
[vagrant@otuslinux ~]$ cat /proc/mdstat
Personalities : [raid10] 
md0 : active raid10 sde[5] sdf[4] sdd[2] sdc[1] sdb[0]
      634880 blocks super 1.2 512K chunks 2 near-copies [5/5] [UUUUU]
      
unused devices: <none>
```

Хотел повторить утреннюю ошибку, но теперь я не могу удалить диск.
Я освободился, а он чем то занят.
```bash
[vagrant@otuslinux ~]$ sudo mdadm /dev/md0 --remove /dev/sde
mdadm: hot remove failed for /dev/sde: Device or resource busy
```

На форуме посоветывали снова отключить его:
```bash
[vagrant@otuslinux ~]$ sudo mdadm --manage /dev/md0 --fail /dev/sde
mdadm: set /dev/sde faulty in /dev/md0
```

Пробую добавить - нет.
```bash
[vagrant@otuslinux ~]$ sudo  mdadm /dev/md0 --add /dev/sde
mdadm: Cannot open /dev/sde: Device or resource busy
```

Сначала читать все нужно, а потом делать.
Удалить - добавить.
Очень странно что есть команда fail.
Я думал это удаление.
А это просто кнопка: "Сделай плохо, пожалуйста"
```bash
[vagrant@otuslinux ~]$ sudo mdadm /dev/md0 --remove /dev/sde
mdadm: hot removed /dev/sde from /dev/md0
[vagrant@otuslinux ~]$ sudo  mdadm /dev/md0 --add /dev/sde
mdadm: added /dev/sde
```
Напомнило:
```java
add action=drop chain=forward dst-address=8.8.8.8 protocol=icmp random=20
```
Кто в душе чуть-чуть сетевик - поймет.

Поймал `rebuilding` командой `watch -n 1 -t 'cat /proc/mdstat'`
```bash
Personalities : [raid10]
md0 : active raid10 sde[5] sdf[4] sdd[2] sdc[1] sdb[0]   
      634880 blocks super 1.2 512K chunks 2 near-copies [5/4] [UUU_U]
      [==================>..]  recovery = 93.7% (239040/253952) finish=0.0min speed=14940K/sec

unused devices: <none>
```
Пока вспомнил. 
Если кто-то из преподавателей читает это, хотелось бы видеть комментарии прямо тут, благо git это позволяет.
В контексте задачи вопросы я думаю, понятнее.
Проходил я как-то курс по питону у Наташи Самойленко, слышали наверняка, там такая система проверки была, 
с комментариями к выполненому студентом заданию, ответами и альтернативными вариантами решения. 
Все в git, в отдельной ветке.

Дальше разделы и создание ФС.
```bash
[root@otuslinux ~]# parted -s /dev/md0 mklabel gpt
```
И сразу непонятное оповещение.
```bash
[root@otuslinux ~]# parted /dev/md0 mkpart primary ext4 0% 20%
Information: You may need to update /etc/fstab.
```
Как-бы я что подумал, это информация, а не ошибка, проигнорирую пока что. 

А как проверить, что `parted` привела к каким то изменениям? 
Да, проверить можно так: `parted /dev/md0; print free`, об этом будет сказано чуть позже.

Следующая команда не найдена.
```bash
[root@otuslinux ~]# mkfs.ext4 /dev/md0p1
-bash: mkfs.ext4: command not found
```
Хорошо. yum install не помог. Может надо было искать mkfs.ext4 ? (не помогло `yum install mkfs.ext4` )
```bash
[root@otuslinux ~]# yum install mkfs
Loaded plugins: fastestmirror
```
Потому что дальше я полез во всем известный поисковик. Форум Centos.org/forum по искомой ошибке порекомендовал
```bash
[root@otuslinux ~]# yum provides "*/mkfs.ext4"
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirror.reconn.ru
 * extras: mirror.satellite-service.ru
 * updates: mirror.satellite-service.ru
base/7/x86_64/filelists_db                                                                                     | 6.9 MB  00:00:24     
extras/7/x86_64/filelists_db                                                                                   | 603 kB  00:00:01     
updates/7/x86_64/filelists_db                                                                                  | 3.4 MB  00:00:04     
e2fsprogs-1.42.9-11.el7.x86_64 : Utilities for managing ext2, ext3, and ext4 filesystems
Repo        : base
Matched from:
Filename    : /usr/sbin/mkfs.ext4



e2fsprogs-1.42.9-12.el7_5.x86_64 : Utilities for managing ext2, ext3, and ext4 filesystems
Repo        : updates
Matched from:
Filename    : /usr/sbin/mkfs.ext4
```
И ничего.
```bash
[root@otuslinux ~]# sudo mkfs.ext4 /dev/md0p1
sudo: mkfs.ext4: command not found
[root@otuslinux ~]# sudo /usr/sbin/mkfs.ext4 /dev/md0p1
sudo: /usr/sbin/mkfs.ext4: command not found
```
Как бы ничего удивительного, в директории то пусто.
```bash
[root@otuslinux ~]# ll /usr/sbin/mkfs*
-rwxr-xr-x. 1 root root  11592 Aug 16 18:47 /usr/sbin/mkfs
-rwxr-xr-x. 1 root root  37080 Aug 16 18:47 /usr/sbin/mkfs.cramfs
-rwxr-xr-x. 1 root root  37184 Aug 16 18:47 /usr/sbin/mkfs.minix
-rwxr-xr-x. 1 root root 368504 Apr 11  2018 /usr/sbin/mkfs.xfs
```

---
Прошло какое-то время и тут я сдался попросив подсказуку.

Вопрос касался вывода команды.
```
[root@otuslinux ~]# parted /dev/md0 mkpart primary ext4 0% 20%                                                   
Information: You may need to update /etc/fstab
```
Это успех, и система информирует нас не забыть прописать mount в fstab.
"В кратце: служит для автоматического монтирования томов в указанные места. В частности /boot и / там прописываются при установке.
Если вы примонтировали какой-то важный том и забыли его прописать в fstab то при следующей загрузке сервера он не смонтируется."

Что примонтировано сейчас
```
cat /etc/fstab
```
Прописываем в /etc/fstab
```bash
echo "#Our new devices" >> /etc/fstab
for i in $(seq 1 5)
do
     echo `sudo blkid /dev/md0p$i | awk '{print $2}'` /u0$i ext4 defaults 0 0 >> /etc/fstab
done
```

C этим более или менее понятно. Партиции у меня создавались корректно.
Даже понятно что он тут хотел от меня - нет свободного места и он предлагает создать партицию нулевого размера.
"Ну он говорит, что мы не можем тебе выделить место где ты просишь, ближайшее которое можем дать - это 47MB to 647MB (sectors 1264640..1264640). Т.е. ничего)))"
```bash
[root@otuslinux ~]# parted /dev/md0 mkpart primary ext4 20% 40%
Warning: You requested a partition from 130MB to 260MB (sectors 253951..507903).
The closest location we can manage is 647MB to 647MB (sectors 1264640..1264640).
Is this still acceptable to you?
Yes/No? yes
Information: You may need to update /etc/fstab.
```
Но чтоб в процессе создания партиций понимать что происходит, смотреть эти команды
```bash
lsblk, fdisk, parted

lsblk #очень наглядно покажет
fdisk -l

parted /dev/md0
print free
```

Я смотрел последнюю
```bash
[root@otuslinux ~]# parted /dev/md0
GNU Parted 3.1
Using /dev/md0
Welcome to GNU Parted! Type 'help' to view a list of commands.
(parted) print free                                                       
Model: Linux Software RAID Array (md)
Disk /dev/md0: 650MB
Sector size (logical/physical): 512B/512B
Partition Table: gpt
Disk Flags: 
Number  Start   End     Size    File system  Name     Flags
 6      17.4kB  2621kB  2604kB               primary
 1      2621kB  131MB   128MB                primary
 2      131MB   260MB   128MB                primary
 3      260MB   391MB   131MB                primary
 4      391MB   519MB   128MB                primary
 5      519MB   647MB   128MB                primary
 7      647MB   647MB   512B                 primary
        647MB   650MB   2604kB  Free Space
(parted) 
```
Видно начальную партицию, 2604kb
видно последнюю - 2604kB
"GPT хранит свои данные там. У него и в начале диска и в конце"
5 партиций в середине.

**Вопрос: Что-то даже осталось неразмеченное, верно? `647MB   650MB   2604kB  Free Space`**

Следующая проблема
```bash
[root@otuslinux ~]# mkfs.ext4 /dev/md0p1
-bash: mkfs.ext4: command not found
```
"Ага. Видимо там немного другой бокс, надо это указать в методичке"
Такой вывод означает, что не найдена команда. Что делать:
1) `which mkfs.ext4` - пусто. Ок. Идем дальше.
2) `find / -name 'mkfs.ext4'` - опять ничего. Ок, значит на системе его нет.
3) `yum provides mkfs.ext4` - говорит что данная тулза лежит в e2fsprogs
Ставим"

"нужно установить пакет `e2fsprogs`"

```bash
[root@otuslinux ~]#  yum install e2fsprogs
```

Вот так выглядит успех при создании файловой системы в партиции:
```bash
[root@otuslinux ~]# mkfs.ext4 /dev/md0p1
mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=1024 (log=0)
Fragment size=1024 (log=0)
Stride=512 blocks, Stripe width=2560 blocks
31360 inodes, 125440 blocks
6272 blocks (5.00%) reserved for the super user
First data block=1
Maximum filesystem blocks=33685504
16 block groups
8192 blocks per group, 8192 fragments per group
1960 inodes per group
Superblock backups stored on blocks: 
        8193, 24577, 40961, 57345, 73729

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done
```
Команда `parted /dev/md0` и `print free` снова выручают
Видно, 5 разделов и на одном есть файловая система, становится понятно, на чем я закончил прошлый раз.
```bash
Number  Start   End     Size    File system  Name     Flags
 6      17.4kB  2621kB  2604kB               primary
 1      2621kB  131MB   128MB   ext4         primary
 2      131MB   260MB   128MB                primary
 3      260MB   391MB   131MB                primary
 4      391MB   519MB   128MB                primary
 5      519MB   647MB   128MB                primary
 7      647MB   647MB   512B                 primary
        647MB   650MB   2604kB  Free Space
```
Либо по одной`sudo mkfs.ext4 /dev/md0p2` 3 4 5
либо однострочным циклом как в методичке
` for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done`
и файловая система есть везде
```bash
 1      2621kB  131MB   128MB   ext4         primary
 2      131MB   260MB   128MB   ext4         primary
 3      260MB   391MB   131MB   ext4         primary
 4      391MB   519MB   128MB   ext4         primary
 5      519MB   647MB   128MB   ext4         primary
```
Создание каталогов под разделы
```bash
mkdir -p /raid/part{1,2,3,4,5}
```
Монтирование каждого раздела в соответствующую директорию
```bash
for i in $(seq 1 5); do mount /dev/md0p$i /raid/part$i; done
```


**Вопрос: Что за директория на нашем пустом разделе?**
```bash
[root@otuslinux ~]# ls -la /raid/part2/
total 17
drwxr-xr-x. 3 root root  1024 Oct 26 17:32 .
drwxr-xr-x. 7 root root  4096 Oct 26 17:35 ..
drwx------. 2 root root 12288 Oct 26 17:32 lost+found
```

---

#### Повторим успех при выходе из строя дисков с урока с реальными файлами.
Накопировал сюда файлов
```bash
[root@otuslinux part1]# pwd
/raid/part1
[root@otuslinux part1]# ll
total 37
-rw-r--r--. 1 root root    38 Oct 26 17:43 12345
-rw-r--r--. 1 root root  1664 Oct 26 17:53 CentOS-Base.repo
-rw-r--r--. 1 root root  1309 Oct 26 17:53 CentOS-CR.repo
-rw-r--r--. 1 root root   649 Oct 26 17:53 CentOS-Debuginfo.repo
-rw-r--r--. 1 root root   314 Oct 26 17:53 CentOS-fasttrack.repo
-rw-r--r--. 1 root root   630 Oct 26 17:53 CentOS-Media.repo
-rw-r--r--. 1 root root  1331 Oct 26 17:53 CentOS-Sources.repo
-rw-r--r--. 1 root root  4768 Oct 26 17:53 CentOS-Vault.repo
drwx------. 2 root root 12288 Oct 26 07:51 lost+found
-rw-r--r--. 1 root root    38 Oct 26 17:50 qqq
```
Чтение
```bash
[root@otuslinux part1]# tail -n2 CentOS-Base.repo 
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
```

Случайно сломался один диск, чтение и запись работают.
```bash
[root@otuslinux part1]# mdadm /dev/md0 --fail /dev/sdb
mdadm: set /dev/sdb faulty in /dev/md0

[root@otuslinux part1]# tail -n2 CentOS-Base.repo 
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[root@otuslinux part1]# echo "#Some text" >> CentOS-Base.repo 
[root@otuslinux part1]# tail -n2 CentOS-Base.repo 
#Some text
```
Когда неожиданно сломался второй диск, результат сохранился.

А вот третий не сломался, видимо таких совпадений не бывает.
```bash
[root@otuslinux part1]# cat /proc/mdstat 
Personalities : [raid10] 
md0 : active raid10 sdb[6](F) sde[5](F) sdf[4] sdd[2] sdc[1]
      634880 blocks super 1.2 512K chunks 2 near-copies [5/3] [_UU_U]
      
unused devices: <none>
[root@otuslinux part1]# mdadm /dev/md0 --fail /dev/sdc
mdadm: set device faulty failed for /dev/sdc:  Device or resource busy
```

**Вопрос: Почему не получается сломать третий диск?**

Восстановление
```bash
[root@otuslinux part1]# mdadm /dev/md0 --remove /dev/sde
mdadm: hot removed /dev/sde from /dev/md0
[root@otuslinux part1]# mdadm /dev/md0 --remove /dev/sdb
mdadm: hot removed /dev/sdb from /dev/md0
[root@otuslinux part1]# mdadm /dev/md0 --add /dev/sde
mdadm: added /dev/sde
[root@otuslinux part1]# mdadm /dev/md0 --add /dev/sdb
mdadm: added /dev/sdb
[root@otuslinux part1]# cat /proc/mdstat 
Personalities : [raid10] 
md0 : active raid10 sdb[6] sde[5] sdf[4] sdd[2] sdc[1]
      634880 blocks super 1.2 512K chunks 2 near-copies [5/3] [_UU_U]
      [==>..................]  recovery = 12.4% (31872/253952) finish=0.4min speed=7968K/sec
      
unused devices: <none>
```

---

#### Нужно написать скрипт в Vagratnfile, чтоб он смог сделать рейд после загрузки
Первая идея - накопировать все необходимые команды в shell

В Vagratnfile все подробности, но там сплошной копипаст.
и сразу вдогонку 

**Вопрос: А можно было как то по другому/изящнее решить эту задачу?**

**Вопрос: Что можете посоветовать почитать, чтоб разобраться в синтаксисе Vagrantfile?**