### LVM

#### Введение в работу с LVM

В vagrantfile добавил сразу,потому что не начиналось без них
- 192.168.33.12
- :box_version => "1804.02",
- yum makecache

А с ними `otuslinux: Complete!`
Каково?
Необъяснимо.

Тоггл говорит, от момента когда я сел делать домашнюю работу и до момента, 
когда операционная система с Vagrantfile загрузилась без ошибок, прошло 
`0:26:53`
Вот такая продуктивность. А вы, 4 часа на ДР закладываете)

На моей коробке диске нет с LVM
```bash
[vagrant@otuslinux ~]$ lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   40G  0 disk 
в””в”Ђsda1   8:1    0   40G  0 part /
sdb      8:16   0  250M  0 disk 
sdc      8:32   0  250M  0 disk 
sdd      8:48   0  250M  0 disk 
sde      8:64   0  250M  0 disk 
sdf      8:80   0  250M  0 disk 
[vagrant@otuslinux ~]$ 
```
А поиск вообще не работает
```bash
[vagrant@otuslinux ~]$ lvmdiskscan
-bash: lvmdiskscan: command not found
```
Может оно и не надо?

Пропустить проблему не удалось. Следующей команды тоже нет.
```bash
[root@otuslinux vagrant]# pvcreate /dev/sdb
bash: pvcreate: command not found
```

Вот что нужно сделать
```bash
yum install -y lvm2
```
Ничего не найдено, как и говорил.
```bash
[root@otuslinux vagrant]# lvmdiskscan
  /dev/sda1 [     <40.00 GiB] 
  /dev/sdb  [     250.00 MiB] 
  /dev/sdc  [     250.00 MiB] 
  /dev/sdd  [     250.00 MiB] 
  /dev/sde  [     250.00 MiB] 
  /dev/sdf  [     250.00 MiB] 
  5 disks
  1 partition
  0 LVM physical volume whole disks
  0 LVM physical volumes
```

Создание Physical Volume
```bash
[root@otuslinux vagrant]# pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.
```
Создание Volume Group
```bash
[root@otuslinux vagrant]# vgcreate otus /dev/sdb
Volume group "otus" successfully created  
```
И создание раздела.
```bash
[root@otuslinux vagrant]#  lvcreate -l+80%FREE -n home otus
  Logical volume "home" created.
```
-l+80%FREE - 80% места занять
-n home - имя тома
otus - ? Это группа что-ли? Судя по выводу следующей команды - да

```bash
[vagrant@otuslinux ~]$ vgdisplay otus
  WARNING: Running as a non-root user. Functionality may be unavailable.
  /run/lvm/lvmetad.socket: connect failed: Permission denied
  WARNING: Failed to connect to lvmetad. Falling back to device scanning.
  /dev/mapper/control: open failed: Permission denied
  Failure to communicate with kernel device-mapper driver.
  Incompatible libdevmapper 1.02.146-RHEL7 (2018-01-22) and kernel driver (unknown version).
  /run/lock/lvm/V_otus:aux: open failed: Permission denied
  Can't get lock for otus
  Cannot process volume group otus
```

Простым пользователям не дано знать ничего о LVM
А я уж пересоздать успел, хотя ничего нового не добавилось.
```bash
[root@otuslinux vagrant]#  lvcreate -l+80%FREE -n home otus
  Logical Volume "home" already exists in volume group "otus"
[root@otuslinux vagrant]# lvcreate -l+80%FREE -n ^C
[root@otuslinux vagrant]# vgdisplay otus
  --- Volume group ---
  VG Name               otus
  System ID             
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  2
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                1
  Open LV               0
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               248.00 MiB
  PE Size               4.00 MiB
  Total PE              62
  Alloc PE / Size       49 / 196.00 MiB
  Free  PE / Size       13 / 52.00 MiB
  VG UUID               rsLc7E-u6na-kEUY-pFkk-tRgq-cMoQ-35cLEz
   
```
**Вопрос: Это размер и количество физических экстентов? 
Я так и не уловил разницу, зачем экстенты разделять на физические и логические?
Мы просто такой формульровкой привязываем к обсуждаемому уровню (PL и LV)?
Значит они могут быть разного размера?
Неужели это в каких-то ситуациях оправдано?**

```
  PE Size               4.00 MiB
  Total PE              62
```

Видимо регистр где то разный
Можно увидеть что в группу входит этот физический раздел, наверняка тут все будут, когда добавим
```bash
[root@otuslinux vagrant]# vgdisplay -v otus | grep 'PV NAME'
[root@otuslinux vagrant]# vgdisplay -v otus | grep 'PV'
  Max PV                0
  Cur PV                1
  Act PV                1
  PV Name               /dev/sdb
```

lvdisplay по tab сразу дописал имя устройства, другие устройства ему не интересны.
```bash
[root@otuslinux vagrant]#  lvdisplay /dev/otus/home
  --- Logical volume ---
  LV Path                /dev/otus/home
  LV Name                home
  VG Name                otus
  LV UUID                5InIq8-PFgu-A3aG-D4kl-745Q-BRFZ-NDc62c
  LV Write Access        read/write
  LV Creation host, time otuslinux, 2018-11-01 18:32:56 +0000
  LV Status              available
  # open                 0
  LV Size                196.00 MiB
  Current LE             49
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     8192
  Block device           253:0
```
**Вопрос: Это размер в логических экстентах?**
```bash
 Current LE             49
```

Кратко если хочется
Суммарное оставшееся пространство в группе (VG)
И информация по разделам (LV) группы (VG)
```bash
[root@otuslinux vagrant]# vgs
  VG   #PV #LV #SN Attr   VSize   VFree 
  otus   1   1   0 wz--n- 248.00m 52.00m
[root@otuslinux vagrant]# lvs
  LV   VG   Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  home otus -wi-a----- 196.00m 
```
Создание LV с точным размером
```bash
[root@otuslinux vagrant]#  lvcreate -L50M -n small otus
  Rounding up size to full physical extent 52.00 MiB
  Logical volume "small" created.
```
Снова суммарная информация
```bash
[root@otuslinux vagrant]# lvs
  LV    VG   Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  home  otus -wi-a----- 196.00m                                                    
  small otus -wi-a-----  52.00m  
```
А вот mkfs без разбора готова попытаться даровать ФС любому устройству.
```bash
[root@otuslinux vagrant]# mkfs.ext4 /dev/
Display all 154 possibilities? (y or n)
```
Удобненько искать
```bash
[root@otuslinux vagrant]# mkfs.ext4 /dev/otus/
home   small
```
Создание ФС. В этот раз, я предусмотрительно оставил в Vagrantfile необходимый пакет
```bash
[root@otuslinux vagrant]# mkfs.ext4 /dev/otus/home 
mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=1024 (log=0)
Fragment size=1024 (log=0)
Stride=0 blocks, Stripe width=0 blocks
50200 inodes, 200704 blocks
10035 blocks (5.00%) reserved for the super user
First data block=1
Maximum filesystem blocks=33816576
25 block groups
8192 blocks per group, 8192 fragments per group
2008 inodes per group
Superblock backups stored on blocks: 
        8193, 24577, 40961, 57345, 73729

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done
```
Создание рядом директории и монтирование нового тома к текущей ФС
```bash
[root@otuslinux vagrant]# ll
total 0
[root@otuslinux vagrant]# pwd
/home/vagrant
[root@otuslinux vagrant]# mkdir /data
[root@otuslinux vagrant]# mount /dev/otus/home /data/
[root@otuslinux vagrant]# mount | grep /data
/dev/mapper/otus-home on /data type ext4 (rw,relatime,seclabel,data=ordered)
```

---

#### LVM Resizing
#### Расширение LVM

**Вопрос: Какая-то беда с отображением всяких символов. Что делать?**
```bash
[root@otuslinux vagrant]# lsblk 
NAME         MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda            8:0    0   40G  0 disk 
в””в”Ђsda1         8:1    0   40G  0 part /
sdb            8:16   0  250M  0 disk 
в”њв”Ђotus-home  253:0    0  196M  0 lvm  /data
в””в”Ђotus-small 253:1    0   52M  0 lvm  
sdc            8:32   0  250M  0 disk 
sdd            8:48   0  250M  0 disk 
sde            8:64   0  250M  0 disk 
sdf            8:80   0  250M  0 disk 
[root@otuslinux vagrant]# 
```
Создание PV и добавление его к VG
```bash
[root@otuslinux vagrant]# pvcreate /dev/sdc
  Physical volume "/dev/sdc" successfully created.
[root@otuslinux vagrant]# vgex
vgexport  vgextend  
[root@otuslinux vagrant]# vgextend otus /dev/sdc
  Volume group "otus" successfully extended
[root@otuslinux vagrant]# vgs
  VG   #PV #LV #SN Attr   VSize   VFree  
  otus   2   2   0 wz--n- 496.00m 248.00m
```
Без -v информации не достаточно.
Ищу имя физических блочных устройств.
```bash
[root@otuslinux vagrant]# vgdisplay 
  --- Volume group ---
  VG Name               otus
  System ID             
  Format                lvm2
  Metadata Areas        2
  Metadata Sequence No  4
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                2
  Open LV               1
  Max PV                0
  Cur PV                2
  Act PV                2
  VG Size               496.00 MiB
  PE Size               4.00 MiB
  Total PE              124
  Alloc PE / Size       62 / 248.00 MiB
  Free  PE / Size       62 / 248.00 MiB
  VG UUID               rsLc7E-u6na-kEUY-pFkk-tRgq-cMoQ-35cLEz
   
[root@otuslinux vagrant]# vgdisplay | grep 'Name'
  VG Name               otus
[root@otuslinux vagrant]# vgdisplay -v | grep 'Name'
  VG Name               otus
  LV Name                home
  VG Name                otus
  LV Name                small
  VG Name                otus
  PV Name               /dev/sdb     
  PV Name               /dev/sdc     
[root@otuslinux vagrant]# vgdisplay -v | grep 'PV Name'
  PV Name               /dev/sdb     
  PV Name               /dev/sdc 
```
Имитация деятельности, после чего весь диск окажется занятым.
```bash
[root@otuslinux vagrant]#  dd if=/dev/zero of=/data/test.log bs=1M count=8000 status=progress
178257920 bytes (178 MB) copied, 3.678860 s, 48.5 MB/s
dd: error writing вЂ/data/test.logвЂ™: No space left on device
181+0 records in
180+0 records out
189128704 bytes (189 MB) copied, 3.77752 s, 50.1 MB/s
```

```bash
[root@otuslinux vagrant]# df -Th /data/
Filesystem            Type  Size  Used Avail Use% Mounted on
/dev/mapper/otus-home ext4  186M  182M     0 100% /data
```

Так, дальше я чутка запутался.
Без диаграммы не понятно.
Мы взяли sdb и создали на нем из 80% логический том.
Потом взяли sdc и занали на нем 50Mb
Потом объединили в группу.
**Вопрос: Сейчас хотим расширить за счет суммарного места в группе?**
**Или мы те 20% оставшихся на sdb берем и отрезаем он них еще 80% ? **
** Относительно чего это +80%FREE ?**
```bash
[root@otuslinux vagrant]# vgs
  VG   #PV #LV #SN Attr   VSize   VFree  
  otus   2   2   0 wz--n- 496.00m 248.00m
```
Расширение
```bash
[root@otuslinux vagrant]# lvextend -l+80%FREE /dev/otus/home 
  Size of logical volume otus/home changed from 196.00 MiB (49 extents) to 396.00 MiB (99 extents).
  Logical volume otus/home successfully resized.
[root@otuslinux vagrant]# 
```

```bash
[root@otuslinux vagrant]# lvs
  LV    VG   Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  home  otus -wi-ao---- 396.00m                                                    
  small otus -wi-a-----  52.00m 
```
Размер свободный в группе изменился. Видимо, относительно группы.
Мы же не могли взять только часть блочного устройства sdb
Мы инициализировали его как одно устройсво
Потом создавали относительно ГРУППЫ с одним устройством том
потом добавили еще устройство
и создали относительно ГРУППЫ второй логический том.
Вроде так.
```bash
[root@otuslinux vagrant]# vgs
  VG   #PV #LV #SN Attr   VSize   VFree 
  otus   2   2   0 wz--n- 496.00m 48.00m
```
Все хорошо, но ФС от этого не выросла.
```bash
[root@otuslinux vagrant]# df -Th /data/
Filesystem            Type  Size  Used Avail Use% Mounted on
/dev/mapper/otus-home ext4  186M  182M     0 100% /data
```
resize файловой системы
```bash
[root@otuslinux vagrant]# resize2fs /dev/otus/home 
resize2fs 1.42.9 (28-Dec-2013)
Filesystem at /dev/otus/home is mounted on /data; on-line resizing required
old_desc_blocks = 2, new_desc_blocks = 4
The filesystem on /dev/otus/home is now 405504 blocks long.
```
Теперь подрос
```bash
[root@otuslinux vagrant]# df -Th /data/
Filesystem            Type  Size  Used Avail Use% Mounted on
/dev/mapper/otus-home ext4  380M  183M  176M  52% /data
```
#### Уменьшение LVM (1:48:10 от начала практики)
Забираю 100 mb. Я так думал. А это просто новый размер.
```bash
[root@otuslinux vagrant]# lvreduce /dev/otus/home -L 100M
  WARNING: Reducing active and open logical volume to 100.00 MiB.
  THIS MAY DESTROY YOUR DATA (filesystem etc.)
Do you really want to reduce otus/home? [y/n]: y
  Size of logical volume otus/home changed from 396.00 MiB (99 extents) to 100.00 MiB (25 extents).
  Logical volume otus/home successfully resized
```

```bash
[root@otuslinux vagrant]# vgs
  VG   #PV #LV #SN Attr   VSize   VFree  
  otus   2   2   0 wz--n- 496.00m 344.00m
[root@otuslinux vagrant]# lvs
  LV    VG   Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  home  otus -wi-ao---- 100.00m                                                    
  small otus -wi-a-----  52.00m                                                    
[root@otuslinux vagrant]# df -Th /data/
Filesystem            Type  Size  Used Avail Use% Mounted on
/dev/mapper/otus-home ext4  380M  183M  176M  52% /data
```
Вот ту не понятно.
**Вопрос: Хорошо, 100 Mb новый диск. Но почему размер ФС перечитать не дает? И автоматоматически размер ФС не уменьшился**
Система кстати сказала, что данные могут быть повреждены, общая фраза, у нас там занато больше чем осталось, это наверняка убъет все данные.
**Вопрос: Данные можно потом восстановить, если сейчас вернуть нужный размер при необходимости пересчитать размер ФС ?**
```bash
[root@otuslinux vagrant]# resize2fs /dev/otus/home 
resize2fs 1.42.9 (28-Dec-2013)
Filesystem at /dev/otus/home is mounted on /data; on-line resizing required
resize2fs: On-line shrinking not supported
[root@otuslinux vagrant]# df -Th /data/
Filesystem            Type  Size  Used Avail Use% Mounted on
/dev/mapper/otus-home ext4  380M  183M  176M  52% /data
```
На сегодня хватит, я думаю. 1:56:59 8:43 PM - 10:40 PM

Копируем содержимое тома
```bash
[root@otuslinux vagrant]#  lvcreate -L 200M -s -n test-snap /dev/otus/home
  Reducing COW size 200.00 MiB down to maximum usable size 104.00 MiB.
  Logical volume "test-snap" created.
```
**Вопрос: Получается, он создался размером равным задатому на текущий момент?**
```bash
Reducing COW size 200.00 MiB down to maximum usable size 104.00 MiB.
```

```bash
[root@otuslinux vagrant]# lsblk
NAME                  MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                     8:0    0   40G  0 disk 
в””в”Ђsda1                  8:1    0   40G  0 part /
sdb                     8:16   0  250M  0 disk 
в”њв”Ђotus-small          253:1    0   52M  0 lvm  
в””в”Ђotus-home-real      253:2    0  100M  0 lvm  
  в”њв”Ђotus-home         253:0    0  100M  0 lvm  /data
  в””в”Ђotus-test--snap   253:4    0  100M  0 lvm  
sdc                     8:32   0  250M  0 disk 
в””в”Ђotus-test--snap-cow 253:3    0  104M  0 lvm  
  в””в”Ђotus-test--snap   253:4    0  100M  0 lvm  
sdd                     8:48   0  250M  0 disk 
sde                     8:64   0  250M  0 disk 
sdf                     8:80   0  250M  0 disk 
[root@otuslinux vagrant]# 
```
Вроде все по инструкции, а получается не так.
**Вопрос: Что случилось, и почему не смог примонтироваться том со снимком?**

```bash
[root@otuslinux vagrant]# mkdir /data-snap
[root@otuslinux vagrant]# mount /dev/otus/test-snap /data-snap/
mount: wrong fs type, bad option, bad superblock on /dev/mapper/otus-test--snap,
       missing codepage or helper program, or other error

       In some cases useful info is found in syslog - try
       dmesg | tail or so.
```
С ФС, откуда делали снимок - все хорошо
На снимке, я полагаю, глупо делать ФС, он скопировать все должен был
```bash
[root@otuslinux vagrant]# df -T        
Filesystem            Type     1K-blocks    Used Available Use% Mounted on
/dev/mapper/otus-home ext4        388712  186998    179639  52% /data
```
Тут не смог отмонтироваться так как был в директории этой
```bash
[root@otuslinux vagrant]# cd /data
[root@otuslinux data]# ll
total 184710
drwx------. 2 root root     12288 Nov  1 18:57 lost+found
-rw-r--r--. 1 root root 189128704 Nov  1 19:14 test.log
[root@otuslinux data]# rm test.log
rm: remove regular file вЂtest.logвЂ™? y
[root@otuslinux data]# ll
total 12
drwx------. 2 root root 12288 Nov  1 18:57 lost+found
[root@otuslinux data]# umount /data
umount: /data: target is busy.
        (In some cases useful info about processes that use
         the device is found by lsof(8) or fuser(1))
[root@otuslinux data]# lsof
bash: lsof: command not found
[root@otuslinux data]# mount | grep home
/dev/mapper/otus-home on /data type ext4 (rw,relatime,seclabel,data=ordered)
[root@otuslinux data]# cd ..
[root@otuslinux /]# umount /data
```
А обратно не монтируется почему-то.
Я не знаю, что пошло не так, но это, видимо, хороший повод все переделать с начала.
```bash
[root@otuslinux /]# lvconvert --merge /dev/otus/test-snap
  Merging of volume otus/test-snap started.
  otus/home: Merged: 100.00%      
[root@otuslinux /]# mount /dev/otus/home /data
mount: wrong fs type, bad option, bad superblock on /dev/mapper/otus-home,
       missing codepage or helper program, or other error

       In some cases useful info is found in syslog - try
       dmesg | tail or so.
```

#### LVM Mirroring

```bash
[root@otuslinux /]# pvcreate /dev/sd{d,e}
  Physical volume "/dev/sdd" successfully created.
  Physical volume "/dev/sde" successfully created.
[root@otuslinux /]#  vgcreate vg0 /dev/sd{d,e}
  Volume group "vg0" successfully created
[root@otuslinux /]#  lvcreate -l+80%FREE -m1 -n mirror vg0
  Logical volume "mirror" created.
[root@otuslinux /]# lvs
  LV     VG   Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  home   otus -wi-a----- 100.00m                                                    
  small  otus -wi-a-----  52.00m                                                    
  mirror vg0  rwi-a-r--- 196.00m                                    100.00 
```

0:58:46
7:24 AM - 8:23 AM

После возвращения в практике случилось необъяснимое.
```
PS E:\Vagrant\sitepoint> vagrant status
Current machine states:

otuslinux                 aborted (virtualbox)
```

Я просто сейчас накопирую команды и создам LV
Кстати по, после повтора, я так и не смог увидеть как уменьшился диск.
```bash
[root@otuslinux vagrant]# df -Th /data/            
Filesystem            Type  Size  Used Avail Use% Mounted on
/dev/mapper/otus-home ext4  415M  372M   18M  96% /data
```
```bash
[root@otuslinux vagrant]# lvreduce /dev/otus/home -L380M
  WARNING: Reducing active and open logical volume to 380.00 MiB.
  THIS MAY DESTROY YOUR DATA (filesystem etc.)
Do you really want to reduce otus/home? [y/n]: y
  Size of logical volume otus/home changed from 436.00 MiB (109 extents) to 380.00 MiB (95 extents).
  Logical volume otus/home successfully resized.
```
```bash
[root@otuslinux vagrant]# df -Th /data/                 
Filesystem            Type  Size  Used Avail Use% Mounted on
/dev/mapper/otus-home ext4  415M  372M   18M  96% /data
```
```bash
[root@otuslinux vagrant]# lvreduce /dev/otus/home -L-35M 
  Rounding size to boundary between physical extents: 32.00 MiB.
  WARNING: Reducing active and open logical volume to 348.00 MiB.
  THIS MAY DESTROY YOUR DATA (filesystem etc.)
Do you really want to reduce otus/home? [y/n]: y
  Size of logical volume otus/home changed from 380.00 MiB (95 extents) to 348.00 MiB (87 extents).
  Logical volume otus/home successfully resized.
[root@otuslinux vagrant]# df -Th /data/                 
Filesystem            Type  Size  Used Avail Use% Mounted on
/dev/mapper/otus-home ext4  415M  372M   18M  96% /data
```
```bash
[root@otuslinux vagrant]# resize2fs /dev/otus/home      
resize2fs 1.42.9 (28-Dec-2013)
Filesystem at /dev/otus/home is mounted on /data; on-line resizing required
resize2fs: On-line shrinking not supported
```
Размер так и не изменился.
**Вопрос: Что я делаю не так?**
```bash
[root@otuslinux vagrant]# df -Th /data/            
Filesystem            Type  Size  Used Avail Use% Mounted on
/dev/mapper/otus-home ext4  415M  372M   18M  96% /data
```

---

### Домашнее задание
#### Уменþшитþ том под / до 8G

Если я правильно понимаю задачу, у нас сейчас установлена ОС и в / есть данные
Нужно не убив систему, сократить размер диска.
Очистил том
```bash
rm /data/*
```
У меня есть подозрение, что sdb мал для переноса /
Создам новую vm

Хотел увеличить и перезагрузить, но не вышло.
```bash
[root@otuslinux vagrant]# lsblk   
NAME         MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda            8:0    0   40G  0 disk 
в””в”Ђsda1         8:1    0   40G  0 part /
sdb            8:16   0  250M  0 disk
```

```bash
[root@otuslinux vagrant]# resize2fs /dev/sdb 
resize2fs 1.42.9 (28-Dec-2013)
resize2fs: Device or resource busy while trying to open /dev/sdb
Couldn't find valid filesystem superblock.
```
Там же lvm у меня
```bash
[root@otuslinux vagrant]#  mkfs.ext4 /dev/sdb 
mke2fs 1.42.9 (28-Dec-2013)
/dev/sdb is entire device, not just one partition!
Proceed anyway? (y,n) n
```
Не смог удалить PV. 
```bash
[root@otuslinux vagrant]# pvremove /dev/sdb
  Can't open /dev/sdb exclusively.  Mounted filesystem?
```
Он не примонтирован
```bash
[root@otuslinux vagrant]# mount | grep data
/dev/sda1 on / type ext4 (rw,relatime,seclabel,data=ordered)
[root@otuslinux vagrant]# umount data/
umount: data/: not mounted
```

Дабы не терять время, я просто пересоздам машину.
**Вопрос, что мне нужно было сделать, чтоб увеличить sdb c 250mb до 5gb когда sdb в lvm и не удаляется.**
Диск увеличен  `:dfile => './sata1.vdi', :size => 5000,`
`vagrant reload`

После пересоздания ВМ все хорошо.
```bash
sdb      8:16   0  4.9G  0 disk
```

Просто накопировал команды
```bash
    3  pvcreate /dev/sdb
    4  vgcreate vg_root /dev/sdb
    5  lsblk 
    6  lvcreate -n lv_root -l +100%FREE /dev/vg_root
    7   mkfs.xfs /dev/vg_root/lv_root
    8  mkfs.xfs /dev/vg_root/lv_root
    9   mount /dev/vg_root/lv_root /mnt
```

Вообще не понятно про что тут команда, аналогии с CP не вижу - откуда - куда
**Вопрос: Что за устройство VolGroup00/LogVol00 ?** Я так понимаю, с него копировать в /mnt
```bash
 xfsdump -J - /dev/VolGroup00/LogVol00 | xfsrestore -J - /mnt
```
Я увидел в конце SUCCESS, но кроме этого были и ошибки
```bash
ERROR: /dev/VolGroup00/LogVol00 does not identify a file system
xfsdump: Dump Status: ERROR
xfsrestore: Restore Status: SUCCESS
```
Пусто
```bash
[root@otuslinux ~]# ll /mnt/
total 0
```
Не выдержал и побрел за помощью.
2:08:37
2:42 PM - 4:50 PM

Пока мне никто не отвечает, приша идея что хоть я и указал версию коробки 1804.02 то стоит проверить, так ли оно.
Как минимум версия текущей много выше, значит и загружать больше нечего.
Подгрузил коробку нужной версии. 
```
PS E:\Vagrant\hw3> vagrant box add centos/7 --box-version '1804.02'
PS E:\Vagrant\hw3> vagrant box list
centos/7        (virtualbox, 1804.02)
centos/7        (virtualbox, 1809.01)
ubuntu/trusty64 (virtualbox, 20181004.0.1)
```
Строка есть `:box_version => "1804.02"` , а как проверить занрузившуюся версию - не понятно
Одной строки было не достаточно. Еще одну добавил.
`box.vm.box_version = boxconfig[:box_version]`
```bash
[vagrant@otuslinux ~]$ df -Th
Filesystem                      Type      Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup00-LogVol00 xfs        38G  6.7G   31G  18% /
```
В очередной раз создал LV и накопировал 
```bash
xfsdump -J - /dev/VolGroup00/LogVol00 | xfsrestore -J - /mnt
```
Зашуршал диск, началось копирование.
**Вопрос: Я так понял, что `xfsdump` копирует данные только с ФС xfs на ФС xfs?
Это могло объяснить пробемы с попытками копирования с ФС ext4 на ФС xfs
Но тогда как я мог выполнить операцию в тех условиях? `cp` или `dd` ?**

Итого - 6:07 PM
```bash
xfsrestore: Restore Status: SUCCESS
```

И вот наконец ожидаемый результат.
```bash
[root@otuslinux ~]# ls /mnt/
bin  boot  dev  etc  home  lib  lib64  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  vagrant  var
```

Следующий шаг - примонтировать текущие папки в / к папкам скопированным на LVM
https://ru.wikipedia.org/wiki/Mount#mount_--bind
*для создания синонима каталога в дереве файловой системы,*

`mount --bind /proc/ /mnt/proc/`
*позволит обращаться к файлам из /proc/ через путь /mnt/proc/, где /mnt/proc/ — некий уже существующий (возможно, пустой) каталог (его настоящее содержимое будет недоступно до момента размонтирования).*
```bash
for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
```

А так должно быть? `chroot` операция изменения корневого каталога диска
**Вопрос: После прочтения информации по ссылке, не понятно, зачем нужна эта команда?
Она нужна только в случаях когда мы перенесои весь корень / в другую директорию (зачем-то) и хотим сказать об этом ситсеме, 
или существуют более практичное и распространенное применение этой команды ?**
```bash
[root@otuslinux /]#  chroot /mnt/
chroot: failed to run command вЂ/bin/bashвЂ™: No such file or directory
```

Переконфигурирование grub - но опять же не понятно, что для текущего граба изменилось, что переконфигурация даст новый результат в новый /
```bash
grub2-mkconfig -o /boot/grub2/grub.cfg
...
*** Creating initramfs image file '/boot/initramfs-3.10.0-862.2.3.el7.x86_64.img' done ***
```
Было так в /boot/grub2/grub.cfg
```bash
linux16 /vmlinuz-3.10.0-862.2.3.el7.x86_64 root=/dev/mapper/VolGroup00-LogVol00 ro no_timer_check console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0 elevator=noop crashkernel=auto rd.lvm.lv=VolGroup00/LogVol00 rd.lvm.lv=VolGroup00/LogVol01 rhgb quiet
```
Есть предположение, что что-то пошло не так, и ОС не грузится успешно.
Хотя я ждал и видел потосы загрузки centos7 в окне VirtualBox. Загрузка была медленной и после исчезновения полосок - ничего.
Удалил машину.

Окончательно пореряв надежду получить сегодня от кого-то помощи, начал нажимать все подряд.
Я не знаю, что это такое и куда я попал, просто добавил наобум директории /usr/ /etc/
```bash
[root@otuslinux /]# for i in /proc/ /sys/ /dev/ /run/ /usr/ /boot/ /etc/; do mount --bind $i /mnt/$i; done
[root@otuslinux /]# chroot /mnt/
bash-4.2# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-862.2.3.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img
done
bash-4.2# 
```
https://askubuntu.com/questions/3402/how-to-move-boot-and-root-partitions-to-another-drive
Вот эта статья натолкнула меня на мысли пытаться натыкать все директори в цикл

**Вопрос: Куда я провалился после `chroot /mnt/` и чем это окружение отличается от предыдущего?**

Смущает тот факт, что в методичке, приглашение для ввода команды такое
```bash
[root@otuslinux ~]# grub2-mkconfig -o /boot/grub2/grub.cfg
```
А у меня, такое
```bash
bash-4.2# grub2-mkconfig -o /boot/grub2/grub.cfg
```
Но вывод похож на вывод из методички.
**Вопрос: Какое тут должен быть приглашение для обновления конфигурации grab grub2-mkconfig -o /boot/grub2/grub.cfg ?**

И всвязи с этой неразберихой с приглашением, непонятно куда вводить следующую команду.

```bash
cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g;
s/.img//g"` --force; done
```
И совершенно непонятно с этими циклами, что делает эта команда.
Лучше бы были пошаговые примеры.

Вот попытка натыкать команду тут `bash-4.2#`
Куча ошибок.
```bash
...
dracut-install: ERROR: installing 'cat'
cp: cannot create regular file
...
```

А если накопировать сюда `[root@otuslinux boot]#` - то похоже на правду становится.
Все еще не понятна разница окружений `bash-4.2#` и `[root@otuslinux boot]#`
```bash
*** Creating image file ***
*** Creating image file done ***
*** Creating initramfs image file '/boot/initramfs-3.10.0-862.2.3.el7.x86_64.img' done ***
```

---

После подсказки обратил внимание на нехватку места на новом диске, пересоберу ВМ на 8GB
```bash
[root@otuslinux boot]# df -h
Filesystem                       Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup00-LogVol00   38G  6.7G   31G  18% /
devtmpfs                         487M     0  487M   0% /dev
tmpfs                            496M  6.8M  490M   2% /run
/dev/sda2                       1014M   61M  954M   6% /boot
/dev/mapper/vg_root-lv_root      4.9G  4.9G  2.3M 100% /mnt
```
После увеличения до 8, и загрузки, рутовая директория стала занимать 9.6Gb
Волшебство.
**Вопрос: Чем могло быть вызвано увеличение размера рутовой партиции, я же увеличивал `:size => 8000,` ?**
```bash
Filesystem                      Type      Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup00-LogVol00 xfs        38G  9.6G   28G  26% /
```
Кстати, с нашим Vagrantfile все в порядке? Проблемы при перезагрузке, он пытается снова жесткие диски создавать, находит их и завершается с ошибкой.
Это какое-то издевательство? 799M ???
```bash
[root@otuslinux ~]# df -Th
Filesystem                      Type      Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup00-LogVol00 xfs        38G  799M   37G   3% /
```

Я в очередной раз повторил все команды
Вот такая занятость по месту после копирования.
```bash
[root@otuslinux ~]# df -Th
Filesystem                      Type      Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup00-LogVol00 xfs        38G  798M   37G   3% /
devtmpfs                        devtmpfs   81M     0   81M   0% /dev
tmpfs                           tmpfs      90M     0   90M   0% /dev/shm
tmpfs                           tmpfs      90M  4.6M   86M   6% /run
tmpfs                           tmpfs      90M     0   90M   0% /sys/fs/cgroup
/dev/sda2                       xfs      1014M   63M  952M   7% /boot
tmpfs                           tmpfs      18M     0   18M   0% /run/user/1000
/dev/mapper/vg_root-lv_root     xfs        10G  808M  9.2G   8% /mnt
```
Монтирование без лишних директорий. **Вопрос: Я не понимаю, зачем нужна эта команда, если копии программ есть в обоих корневых директориях и можно к ним обратиться?**
```bash
for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
```

Наконец, то отработала
```bash
chroot /mnt/
```
И я куда-то провалился. Это было незаметно, но судя по истории, отсутсвию файлов в `/mnt` -  я тут недавно.
```bash
[root@otuslinux /]# ll /mnt/
total 0
[root@otuslinux /]# ^C
[root@otuslinux /]# ll /mnt/
total 0
[root@otuslinux /]# history 
    1  ll /mnt/
    2  history
```
Так как мы в новом окружении из новой корневой директории, что то должно поменяться в конфигурации grab
Что? Путь к папке boot ?
```bash
[root@otuslinux /]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-862.2.3.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img
done
```
Страшно длинная и не понятная команда
```bash
cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g;
s/.img//g"` --force; done
```
Не понятно, зачем цикл, если тут одна строка всего
```bash
[root@otuslinux /]# cd /boot/
[root@otuslinux boot]# ls initramfs-*img
initramfs-3.10.0-862.2.3.el7.x86_64.img
```
Что делает dracut -v ?
http://parallel.uran.ru/node/405
http://www.bog.pp.ru/work/dracut.html
*dracut - утилита создания initramfs*

Форматирование строки - выбор только версии
```bash
[root@otuslinux boot]# echo initramfs-3.10.0-862.2.3.el7.x86_64.img|sed "s/initramfs-//g;s/.img//g"
3.10.0-862.2.3.el7.x86_64
```

Предполагаю, с оригинале команда выглядит как-то так:
```bash
dracut -v initramfs-3.10.0-862.2.3.el7.x86_64.img 3.10.0-862.2.3.el7.x86_64 --force
```
Ответ был в выводе команды, так что не буду повторять отдельную команду
```bash
Executing: /sbin/dracut -v initramfs-3.10.0-862.2.3.el7.x86_64.img 3.10.0-862.2.3.el7.x86_64 --force
```
Поменял rd.lvm.lv=VolGroup00/LogVol00
```bash
rd.lvm.lv=vg_root/lv_root
```

Там еще осталось, но я не тронул.
Вроде как корневая папка может искаться в 2х метсах?
```bash
rd.lvm.lv=VolGroup00/LogVol01
```
Не дал почему то перезагрузиться из `chroot`
```bash
[root@otuslinux boot]# reboot 
Running in chroot, ignoring request
```
Предположу, что тут мы увидели примонтированный корень к sdb
```bash
sdb                       8:16   0   10G  0 disk 
в””в”Ђvg_root-lv_root       253:0    0   10G  0 lvm  /
```

Удаление старого LV и создание нового
```bash
[root@otuslinux ~]# lvremove /dev/VolGroup00/LogVol00 
Do you really want to remove active logical volume VolGroup00/LogVol00? [y/n]: y
  Logical volume "LogVol00" successfully removed

[root@otuslinux ~]# lvcreate -n VolGroup00/LogVol00 -L 8G /dev/VolGroup00
WARNING: xfs signature detected on /dev/VolGroup00/LogVol00 at offset 0. Wipe it? [y/n]: y
  Wiping xfs signature on /dev/VolGroup00/LogVol00.
  Logical volume "LogVol00" created.
[root@otuslinux ~]# 
```

Так, корень у нас на sdb на LV
LV пишет свой конфиг на диски, поэтому никакого конфига и прописывания перед перезагрузкой.
Но вот чего я не понял.
**Вопрос: LV после перезагрузки сохраняется, а вот что и куда монтируется при загрузке нужно в fstab как я понял писать, так вот, в тех манипуляциях мне не понятно, где мы наш LV lv_root на sdb мы примонтировали к / на постоянной основе?**

Ясное дело, /mnt не сохранилось, мы же в fstab не писали ничего.
Так вот, новый созданный только что LV монтируем туда же, для простоты
```bash
mkfs.xfs /dev/VolGroup00/LogVol00 
mount /dev/VolGroup00/LogVol00 /mnt/
```
Копирование данных
```bash
xfsdump -J - /dev/vg_root/lv_root | xfsrestore -J - /mnt
```

```bash
for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
chroot /mnt/
grub2-mkconfig -o /boot/grub2/grub.cfg
```

Создание отдельного раздела под /var - и чем так chroot хорош, что именно в нем это удобнее делать?
Потому что именно относительно новго пути / нужно все манипуляции проводить?

Cоздание новой группы и LV, ФС и монтирование. Как обычно.
```bash
pvcreate /dev/sdc /dev/sdd
vgcreate vg_var /dev/sdc /dev/sdd
lvcreate -L 950M -m1 -n vl_var vg_var
mkfs.ext4 /dev/vg_var/vl_var 
```
`-m1` - признак зеркала

Кстати, вот тут важно, что монтируем мы уже относительно нового корня / и тут /mnt пуст.
Но я не думаю, что тут же var и останется, это скорее временное монтирование для копирования файлов на ФС
```bash
mount /dev/vg_var/vl_var /mnt/
```
Конечно это не верное время, ибо я не учитывал его пока тупил и не понимал что происходит.
1:36:47 9:20 PM - 10:57 PM

А вот копируем по новому.
Из текущего корня, куда только что 
```bash
cp -aR /var/* /mnt/
```

Некоторое время сложно было понять, на какой я стадии процесса.
```bash
   23  lvs
   24  mount | grep v_var
   25  lsblk 
   26  df -Th # Тут же я вижу что есть устройство /dev/mapper/vg_var-vl_var       ext4      922M  135M  724M  16% /mnt
   27  mkfs.ext4 /dev/vg_var/lv_var # Could not stat /dev/vg_var/lv_var --- No such file or directory - Первое что смутило, долже же быть все на месте!
   28  mount /dev/vg_var/lv_var /mnt # mount: special device /dev/vg_var/lv_var does not exist - и эта ругается, да чтож такое, 
   #**Вопрос: А может оно занято тк смонтировано и поэтому его как бы нет?**
   29  vgs
   30  lvcreate -L 950M -m1 -n lv_var vg_var # Insufficient free space: 478 extents needed, but only 288 available - потому что места больше нет, а не потому что имя занято уже
   31  mkfs.ext4 /dev/vg_var/lv_var # The device apparently does not exist; did you specify it correctly?
   32  lvremove /dev/lv_var
   33  lvremove /dev/vg_var/vl_var #  Logical volume vg_var/vl_var contains a filesystem in use. - Таки занят
   34  mount # Вот он примонтирован /dev/mapper/vg_var-vl_var on /mnt type ext4 (rw,relatime,seclabel,data=ordered)
   35  ll /mnt/ # Тут видно внутренности /var
   36  cp -aR /var/* /mnt/ #
   37  cp -aRy /var/* /mnt/ #
   38  cp -aRf /var/* /mnt/ #
   39  yes | cp -aRf /var/* /mnt/ # Зачем то все перезаписал
```

*На всāкий случай сохранāем содержимое старого var (или же можно его просто удалитþ)*
```bash
   40  mkdir /tmp/oldvar && mv /var/* /tmp/oldvar # 
```
Теперь нужно отмонтировать он временной точки монтирования /mnt чтоб примонтировать на место, откуда якобы, должны все удалить (на самом деле перенесли)
```bash
   41  umount /mnt #
```
А тут монтируем директорию в место, откуда накопировали данные.
```bash
   42  mount /dev/vg_var/lv_var /var # mount: special device /dev/vg_var/lv_var does not exist
   43  lvs #
   44  mount /dev/vg_var/vl_var /var/ # Тут я не копировал а воспользовался TAB
   45  mount /dev/vg_var/vl_var /var # /dev/mapper/vg_var-vl_var is already mounted or /var busy
   46  umount /var #
   47  mount /dev/vg_var/vl_var /var #
```
Чтоб при перезагрузке все примонтировалось как нужно - в fstab
```bash
   48  echo "`blkid | grep var: | awk '{print $2}'` /var ext4 defaults 0 0" >> /etc/fstab
```
Эхо отдает уникальный номер устройства
```bash
UUID="a71dcadb-fe2b-4725-8d07-3e8f01a7d0b4"
```
Полная строка для добавления устройства в точку монтировани выглядит так
```bash
UUID="a71dcadb-fe2b-4725-8d07-3e8f01a7d0b4" /var ext4 defaults 0 0
```

Удаление временных директорий под root /  
```bash
[root@otuslinux vagrant]# lvremove /dev/vg_root/lv_root 
Do you really want to remove active logical volume vg_root/lv_root? [y/n]: y
  Logical volume "lv_root" successfully removed
[root@otuslinux vagrant]# vgremove 
vg_root     vg_var      VolGroup00  
[root@otuslinux vagrant]# vgremove /dev/ vgremove /dev/vg_root^C
[root@otuslinux vagrant]#  vgremove /dev/vg_root
  Volume group "vg_root" successfully removed
[root@otuslinux vagrant]# pvremove /dev/sdb
  Labels on physical volume "/dev/sdb" successfully wiped.
[root@otuslinux vagrant]# 
```

`lvcreate -n LogVol_Home -L 2G /dev/VolGroup00`
Создание LV в существующей группе
```bash
[root@otuslinux vagrant]# lvs
  LV          VG         Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  LogVol00    VolGroup00 -wi-ao----   8.00g                                                    
  LogVol01    VolGroup00 -wi-ao----   1.50g                                                    
  LogVol_Home VolGroup00 -wi-a-----   2.00g                                                    
  vl_var      vg_var     rwi-aor--- 952.00m                                    100.00          
```

```bash
mkfs.xfs /dev/VolGroup00/LogVol_Home
```

```bash
   74  mount /dev/VolGroup00/LogVol_Home /mnt/ # Монтируем том чтоб скопировать в него данные
   75  cp -aR /home/* /mnt/ # Копирование
   76  rm -rf /home/* # удаление содержимого, а можно было mv сделать?
   77  umount /mnt/ # Отмонтирование
   78  mount /dev/VolGroup00/LogVol_Home /home/ #
   79  blkid | grep Home # Хочу вручную добавить запись - смотрю ID 
   80  echo UUID="b3ad6b54-33ef-479e-8343-e798060c51bf" /home xfs defaults 0 0 # Тут нет ковычек - что делать?
   84  tail -n1 /etc/fstab  #
   85  vi /etc/fstab  # Просто накопировал в vi и добавил ковычи
   87  touch /home/file{1..21} # Создание тестовых файлов
   88  ll /home/ #
```

`/dev/mapper/VolGroup00-LogVol_Home xfs       2.0G   33M  2.0G   2% /home`
Видно что 33M только занято, поэтому снимка в 100 будет достаточно
```bash
 lvcreate -L 100MB -s -n home_snap /dev/VolGroup00/LogVol_Home
```

```bash
[root@otuslinux vagrant]# lvcreate -L 100MB -s -n home_snap /dev/VolGroun00/LogVol_Home # Это я набирал руками и что то пошло не так - потому что ошибка - TAB не работал
  Volume group "VolGroun00" not found
  Cannot process volume group VolGroun00

[root@otuslinux vagrant]# lvcreate -L 100MB -s -n home_snap /dev/VolGroup00/LogVol_Home # Это я копировал и все хорошо
  Rounding up size to full physical extent 128.00 MiB
  Logical volume "home_snap" created.
[root@otuslinux vagrant]# 

```

```bash
[root@otuslinux vagrant]# rm -f /home/file{11..19} # Удалить файлики
[root@otuslinux vagrant]# umount /home # Отмонтировать перед восстановлением
[root@otuslinux vagrant]# lvconvert --merge /dev/VolGroup00/home_snap # Команда для восставновления из снимка
  Merging of volume VolGroup00/home_snap started. #
  VolGroup00/LogVol_Home: Merged: 100.00% #
[root@otuslinux vagrant]# mount /home/ #
```
**Вопрос: Почему LV пропал после восстановления?**
```bash
[root@otuslinux vagrant]# lvs
  LV          VG         Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  LogVol00    VolGroup00 -wi-ao----   8.00g                                                    
  LogVol01    VolGroup00 -wi-ao----   1.50g                                                    
  LogVol_Home VolGroup00 -wi-ao----   2.00g                                                    
  vl_var      vg_var     rwi-aor--- 952.00m                                    100.00  

```
Вот, его нет
```bash
[root@otuslinux vagrant]# umount /home
[root@otuslinux vagrant]# lvconvert --merge /dev/VolGroup00/home_snap 
  Failed to find logical volume "VolGroup00/home_snap"
```

Повторил, и правда после восстановления все исчезло
```bash
[root@otuslinux vagrant]# umount /home
[root@otuslinux vagrant]# lvconvert --merge /dev/VolGroup00/home_snap 
  Merging of volume VolGroup00/home_snap started.
  VolGroup00/LogVol_Home: Merged: 100.00%
[root@otuslinux vagrant]# lsblk       
NAME                       MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                          8:0    0   40G  0 disk 
в”њв”Ђsda1                       8:1    0    1M  0 part 
в”њв”Ђsda2                       8:2    0    1G  0 part /boot
в””в”Ђsda3                       8:3    0   39G  0 part 
  в”њв”ЂVolGroup00-LogVol00    253:0    0    8G  0 lvm  /
  в”њв”ЂVolGroup00-LogVol01    253:1    0  1.5G  0 lvm  [SWAP]
  в””в”ЂVolGroup00-LogVol_Home 253:2    0    2G  0 lvm  
sdb                          8:16   0   10G  0 disk 
sdc                          8:32   0    2G  0 disk 
в”њв”Ђvg_var-vl_var_rmeta_0    253:3    0    4M  0 lvm  
в”‚ в””в”Ђvg_var-vl_var          253:7    0  952M  0 lvm  /var
в””в”Ђvg_var-vl_var_rimage_0   253:4    0  952M  0 lvm  
  в””в”Ђvg_var-vl_var          253:7    0  952M  0 lvm  /var
sdd                          8:48   0    1G  0 disk 
в”њв”Ђvg_var-vl_var_rmeta_1    253:5    0    4M  0 lvm  
в”‚ в””в”Ђvg_var-vl_var          253:7    0  952M  0 lvm  /var
в””в”Ђvg_var-vl_var_rimage_1   253:6    0  952M  0 lvm  
  в””в”Ђvg_var-vl_var          253:7    0  952M  0 lvm  /var
sde                          8:64   0    1G  0 disk 
sdf                          8:80   0  256M  0 disk 
sdg                          8:96   0  256M  0 disk 

```

Добавил в fstab auto ro напртив home чтоб попробовать. Хотя у меня и в самом начале не сработала команда `sudo su -`
Но я не обратил внимания
А теперь я и презагрузиться не могу из cli
Перезагрузил ВМ из VBox
в fstab запись работает
```bash
UUID="b3ad6b54-33ef-479e-8343-e798060c51bf" /home auto ro xfs defaults 0 0
```
```bash
[root@otuslinux vagrant]# rm /home/file1
rm: remove regular empty file вЂ/home/file1вЂ™? y
rm: cannot remove вЂ/home/file1вЂ™: Read-only file system
```
Вот что мне система на reboot ответила
```bash
Error getting authority: Error initializing authority: Error calling StartServiceByName for org.freedesktop.PolicyKit1: Timeout was reached (g-io-error-quark, 24)
Failed to start reboot.target: Connection timed out
See system logs and 'systemctl status reboot.target' for details.
```

метод из гугла не помог
https://unix.stackexchange.com/questions/249575/systemctl-keeps-timing-out-on-service-restart
```bash
systemctl start polkit
```
**Вопрос: Почему возникла проблема с перезагрузкой?**

---
### Развлечения с btrfs
https://wiki.gentoo.org/wiki/Btrfs/ru
http://xgu.ru/wiki/Btrfs

Создание raid1
```bash
[root@otuslinux /]# mkfs.btrfs -m raid1 /dev/sd{e,f,g} -d raid1 /dev/sd{e,f,g}
btrfs-progs v4.9.1
See http://btrfs.wiki.kernel.org for more information.

ERROR: skipping duplicate device /dev/sde in the filesystem
ERROR: skipping duplicate device /dev/sdf in the filesystem
ERROR: skipping duplicate device /dev/sdg in the filesystem
Label:              (null)
UUID:               003ed6e8-1469-4731-b9f9-e5d7e08fb8d2
Node size:          16384
Sector size:        4096
Filesystem size:    
Block group profiles:
  Data:             RAID1            76.75MiB
  Metadata:         RAID1            76.75MiB
  System:           RAID1             8.00MiB
SSD detected:       no
Incompat features:  extref, skinny-metadata
Number of devices:  3
Devices:
   ID        SIZE  PATH
    1     1.00GiB  /dev/sde
    2   256.00MiB  /dev/sdf
    3   256.00MiB  /dev/sdg
```

Монтирование по UUID
```bash
[root@otuslinux /]# mount -U 003ed6e8-1469-4731-b9f9-e5d7e08fb8d2 /mnt/
```

`lsblk` выдает что только первый диск примонтирован, а общий объем btrfs raid1 - 1.50GiB
**Вопрос: Почему в `lsblk` примонтирован только один том и почему я не увидел новго блочного устройства в выводе этой команды, как в случае с LV?**
```bash
sde                          8:64   0    1G  0 disk /opt
sdf                          8:80   0  256M  0 disk 
sdg                          8:96   0  256M  0 disk 
```

создание подтома
```bash
[root@otuslinux /]# btrfs subvolume create /mnt/sub1
Create subvolume '/mnt/sub1'
[root@otuslinux /]# btrfs subvolume list /mnt/
ID 256 gen 8 top level 5 path sub1
```
Подтом перенесся после дкмонтирования
```bash
[root@otuslinux /]# umount /mnt/
[root@otuslinux /]# mount -U 003ed6e8-1469-4731-b9f9-e5d7e08fb8d2 /opt
[root@otuslinux /]# btrfs subvolume list /opt/
ID 256 gen 8 top level 5 path sub1
[root@otuslinux /]# 
```
Выглядит как директория
```bash
[root@otuslinux /]# ll /opt/
total 0
drwxr-xr-x. 1 root root 0 Nov  4 23:44 sub1
```
Создание снимка
```bash
[root@otuslinux /]# ll /opt/
total 0
drwxr-xr-x. 1 root root 0 Nov  4 23:44 sub1
[root@otuslinux /]# touch /opt/sub1/file{1..11}
[root@otuslinux /]# ll /opt/sub1/
total 0
-rw-r--r--. 1 root root 0 Nov  4 23:53 file1
-rw-r--r--. 1 root root 0 Nov  4 23:53 file10
-rw-r--r--. 1 root root 0 Nov  4 23:53 file11
-rw-r--r--. 1 root root 0 Nov  4 23:53 file2
-rw-r--r--. 1 root root 0 Nov  4 23:53 file3
-rw-r--r--. 1 root root 0 Nov  4 23:53 file4
-rw-r--r--. 1 root root 0 Nov  4 23:53 file5
-rw-r--r--. 1 root root 0 Nov  4 23:53 file6
-rw-r--r--. 1 root root 0 Nov  4 23:53 file7
-rw-r--r--. 1 root root 0 Nov  4 23:53 file8
-rw-r--r--. 1 root root 0 Nov  4 23:53 file9
[root@otuslinux /]# btrfs subvolume snapshot /opt/sub1/ /opt/sub1s
Create a snapshot of '/opt/sub1/' in '/opt/sub1s'
[root@otuslinux /]# ll /opt/
total 0
drwxr-xr-x. 1 root root 114 Nov  4 23:53 sub1
drwxr-xr-x. 1 root root 114 Nov  4 23:53 sub1s
[root@otuslinux /]# ll /opt/sub1s/
total 0
-rw-r--r--. 1 root root 0 Nov  4 23:53 file1
-rw-r--r--. 1 root root 0 Nov  4 23:53 file10
-rw-r--r--. 1 root root 0 Nov  4 23:53 file11
-rw-r--r--. 1 root root 0 Nov  4 23:53 file2
-rw-r--r--. 1 root root 0 Nov  4 23:53 file3
-rw-r--r--. 1 root root 0 Nov  4 23:53 file4
-rw-r--r--. 1 root root 0 Nov  4 23:53 file5
-rw-r--r--. 1 root root 0 Nov  4 23:53 file6
-rw-r--r--. 1 root root 0 Nov  4 23:53 file7
-rw-r--r--. 1 root root 0 Nov  4 23:53 file8
-rw-r--r--. 1 root root 0 Nov  4 23:53 file9
[root@otuslinux /]# 
```
В fstab
```bash
UUID="003ed6e8-1469-4731-b9f9-e5d7e08fb8d2" /opt btrfs defaults 0 0
```
Вопрос: Где взять UUID каждого подразжела чтоб кажды отдельно прописать в fstab?
Ответ:
```bash
[root@otuslinux /]# btrfs subvolume list -u /opt/                     
ID 256 gen 11 top level 5 uuid 43f2e8e8-c605-d94f-9987-3190150ab0d2 path sub1
ID 257 gen 11 top level 5 uuid 74162d47-bdfe-e94a-96e5-bf22a2b119f2 path sub1s
```

Понял как монтировать подтома
```bash
  194  btrfs subvolume delete /opt/sub1s/ # Удалил снимок подтома
  195  btrfs subvolume delete /opt/sub1/ # Удалил подтом
  196  btrfs subvolume list -u /opt/ # Убедился что пусто
  197  umount /opt/ # Отмонтировал
  198  mount -U 003ed6e8-1469-4731-b9f9-e5d7e08fb8d2 /mnt/ # Примонтировал Raid -или я думаю что это raid
  199  btrfs subvolume create /mnt/opt # Создал подтом для opt
  200  btrfs subvolume snapshot /mnt/opt/ /mnt/optsnap # Создал подтом-снимок для opt - конечно он пустой
  203  btrfs subvolume list -u /mnt/ # Нашел UUID чтоб прописать подтом в fstab
  204  vi /etc/fstab  #
```

```bash
btrfs subvolume snapshot -r /home /home_BACKUP              # создаем read-only снимок - send требует, что бы отправляемый снимок был read-only
```
Что нужно было сделатьс кэшкм - пока не понятно

11:18 AM - 3:03 PM
3:45:21

---
PS.
Создал на основе этой машины - коробку
http://sysadm.pp.ua/linux/sistemy-virtualizacii/vagrant-box-creation.html
'otuslinux' - текущее имя машины в VB - кстати, была запущена
```bash
vagrant package --base 'otuslinux' --output lvm_root8g_varhome_optbtrfs_template
```
Добавление коробки в список доступных и проверка
```bash
PS E:\Vagrant\sitepoint> vagrant box add lvm_root8g_varhome_optbtrfs_template --name 'centos7-hw3-result'
==> box: Box file was not detected as metadata. Adding it directly...
==> box: Adding box 'centos7-hw3-result' (v0) for provider:
    box: Unpacking necessary files from: file://E:/Vagrant/sitepoint/lvm_root8g_varhome_optbtrfs_template
    box: Progress: 100% (Rate: 834M/s, Estimated time remaining: --:--:--)
==> box: Successfully added box 'centos7-hw3-result' (v0) for 'virtualbox'!
PS E:\Vagrant\sitepoint> .\vagrant_module2_fs_raid_4.log^C
PS E:\Vagrant\sitepoint> vagrant box list
centos/7           (virtualbox, 1804.02)
centos/7           (virtualbox, 1809.01)
centos7-hw3-result (virtualbox, 0)
ubuntu/trusty64    (virtualbox, 20181004.0.1)
```