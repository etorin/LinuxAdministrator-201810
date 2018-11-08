### 1. Попасть в систему без пароля несколькими способами
####Первый успешный способ
*2.3. CentOS 7, облачный сервер*
https://www.servers.ru/knowledge/linux-administration/how-to-reset-root-password-on-centos-6-and-centos-7#setting_new_password
Дождаться grub, нажать "е" для редактирования
1. удаление rhgb and quiet, дописывание rd.break enforcing=0 - не помогло 
Отсюда:
(https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/system_administrators_guide/sec-terminal_menu_editing_during_boot#sec-Changing_and_Resetting_the_Root_Password)
2. удаление rhgb and quiet, замена ro на rw, дописывание rd.break enforcing=0 - не помогло 
3. замена ro на rw, дописывание rd.break enforcing=0 и удаение слежкющих ключей console= со значениями - помогло - попал в shell без пароля
Приветствие:
`switch_root:/#`

```bash
chroot /sysroot
passwd root
touch /.autorelabel
exit
reboot
```
Сменил пароль vagrant - после перезагруки не подходит оба!
Ровно по этой инструкции сделал на centos7 на VMW которую ставил руками с iso - заработало.
**Вопрос: Что могло пойти не так, и на одной ВМ метод стработал, а на другой - нет? На что влияет команда `touch /.autorelabel`**
2:02:12
3:51 PM - 5:53 PM


#### Второй способ
https://www.liberiangeek.net/2014/09/reset-forgotten-root-password-centos-7-servers/
Нам предлагают задать init
`init=/sysroot/bin/sh`

а заработало так в строке linux16
- ro
+ rw 
+ init=/sysroot/bin/sh 
- quiet

Приглашение и команды
```bash
:/#
:/# chroot /sysroot/
passwd root
exit
reboot
```
И снова не подходит ни один пароль.
Ладно хоть снимок сделал. Откатываю.
Я заметил что в настройках grub2 можно указать UUID
**Вопрос: Получается, ему так на любое устройство указать можно? На LV, на raid?**

Отсутствие команды `touch /.autorelabel` видимо повлияло на результат. update SELinux parameters

Может это еще один вариант смены пароля, но видимо, я не понял что это такое.
```bash
systemd.unit=emergency.target
systemd.unit=rescue.target
```

---
### 2. Установить систему с LVM, после чего переименовать VG
с образа CentOS-7-x86_64-DVD-1804.iso
https://www.tecmint.com/centos-7-installation/

После установки не мог подключиться по ssh
пока не поменял тип адаптера с NAT на адаптер Vbox host-only Ethernet #2
и пока вручну не сгенерировал ключ ssh командой ssh-keygen

Все по инструкции натыкано, вот текущие группы LVM
```bash
[root@hw4test ~]# vgs
  VG     #PV #LV #SN Attr   VSize  VFree
  centos   1   2   0 wz--n- <7,50g    0 
[root@hw4test ~]# lvs
  LV   VG     Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  root centos -wi-ao----  <6,70g                                                    
  swap centos -wi-ao---- 820,00m                                                    
[root@hw4test ~]# 
```

Благо, для переименования группы есть специальная команда.
```bash
[root@hw4test ~]# vgrename /dev/centos /dev/centos1
  Volume group "centos" successfully renamed to "centos1"

```

```bash
[root@hw4test ~]# vgs
  VG      #PV #LV #SN Attr   VSize  VFree
  centos1   1   2   0 wz--n- <7,50g    0 
[root@hw4test ~]# lvs
  LV   VG      Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  root centos1 -wi-ao----  <6,70g                                                    
  swap centos1 -wi-ao---- 820,00m                                                    
[root@hw4test ~]# 
```
И система не загрузилась, выдав приветствие `dracut#`
Попробовал как с восстановлением пароля в shell туда попасть - опять долгая загрузка и в `dracut#`
`chroot /sysroot/` из `dracut#` сделать не дает.
**Вопрос: Это можно было как-то починить. 
Я нешел инструкцию, как правильно менять имя VG 
и следующим после rename там предлагается править файл `/etc/defaults/grub`, 
можно продолжить это делать из той стадии, где я оказался (`dracut#`)?**

Не спрашивайте зачем это тут.
```bash
hostnamectl set-hostname NEW_HOSTNAME
```

**Вопрос: Как правильно, vgrename -v centos1 centos или через /dev/centos?
Можно выше посмотреть, у той команды вывод меньше, отсюда и вопрос.**
На этот вывод не смотреть в контексте задания, слелал после успеха для примера и вопроса
```bash
[root@hw4test ~]# vgrename -v centos1 centos
    Wiping cache of LVM-capable devices
    Archiving volume group "centos1" metadata (seqno 8).
    Writing out updated volume group
    Renaming "/dev/centos1" to "/dev/centos"
    Loading table for centos1-LogVol00 (253:0).
    Suppressed centos1-LogVol00 (253:0) identical table reload.
    Suspending centos1-LogVol00 (253:0) with device flush
    Loading table for centos1-LogVol00 (253:0).
    Suppressed centos1-LogVol00 (253:0) identical table reload.
    Renaming centos1-LogVol00 (253:0) to centos-LogVol00
    Resuming centos-LogVol00 (253:0).
    Loading table for centos1-LogVol01 (253:1).
    Suppressed centos1-LogVol01 (253:1) identical table reload.
    Suspending centos1-LogVol01 (253:1) with device flush
    Loading table for centos1-LogVol01 (253:1).
    Suppressed centos1-LogVol01 (253:1) identical table reload.
    Renaming centos1-LogVol01 (253:1) to centos-LogVol01
    Resuming centos-LogVol01 (253:1).
    Creating volume group backup "/etc/lvm/backup/centos" (seqno 9).
  Volume group "centos1" successfully renamed to "centos"
[root@hw4test ~]# 
```

Снова переименование, потому что ту машину я не оживид из dracut#
```bash
[root@hw4test ~]# vgrename /dev/centos /dev/centos1
  Volume group "centos" successfully renamed to "centos1"
```
Снова видно название, проблема прошлой попытки - я не поменял это имя там, где используется старое
```bash
[root@hw4test ~]# vgs
  VG      #PV #LV #SN Attr   VSize   VFree
  centos1   1   2   0 wz--n- <38.97g    0 
  vg_var    2   1   0 wz--n-   2.99g 1.12g
```

```bash
vi /etc/defaults/grub

```
Вот тут поменял
```bash
GRUB_CMDLINE_LINUX="no_timer_check console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0 elevator=noop crashkernel=auto rd.lvm.lv=centos1/LogVol00 rd.lvm.lv=centos1/LogVol01 rhgb quiet"
```

Тут поменял
```bash
# /etc/fstab
# Created by anaconda on Sat May 12 18:50:26 2018
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
/dev/mapper/centos1-LogVol00 /                       xfs     defaults        0 0
UUID=570897ca-e759-4c81-90cf-389da6eee4cc /boot                   xfs     defaults
   0 0
/dev/mapper/centos1-LogVol01 swap 
```

Перезагрузка
При агрузке - удивление - настройках граба все езе старое имя прописано!
**Вопрос: Я менял в параметр GRUB_CMDLINE_LINUX в /etc/defaults/grub, почему при загрузке машина не учла это, пыталась начаться с rd.lvm.lv=VolG/LogVol00 тами парметром?
Пришлось править grub перед загрузкой, и вместо rd.lvm.lv=VolG/LogVol00 ставить новое имя - и после этого ОС началась**

После этого нашел что нужно вызвать еще одну команду, непонятно зачем если конфиг мы уже поменяли вручную.
```bash
grub2-mkconfig -o /boot/grub2/grub.cfg  
```
Но это помогло и больше при загрузке проблем нет.

--- 

### 3. Добавить модуль в initrd

Как по слайдам - не получилось
Просто скопировал - и ничего не увидел при загрузке (quiet убрал)
```bash
/usr/lib/dracut/modules.d/01test/module-setup.sh
/usr/lib/dracut/modules.d/01test/test.sh 
```

В списке есть, поправил права на файл
```bash
[root@localhost ~]# dracut --list-modules
bash
systemd-bootchart
test
```

Дописал в существующий модуль - `00bash/module-setup.sh` - тоже при загрузке ничего не увидел
```
echo LOADING!LOADING!ATTENTION!ATTENTION!
echo LOADING!LOADING!ATTENTION!ATTENTION!
echo LOADING!LOADING!ATTENTION!ATTENTION!
echo LOADING!LOADING!ATTENTION!ATTENTION!
echo LOADING!LOADING!ATTENTION!ATTENTION!
echo LOADING!LOADING!ATTENTION!ATTENTION!
sleep 10
```
И хоть я и убираю quiet в настройках grub перед загрузкой, все равно после некоторого вывода вижу полоски загрузки centos.
**Вопрос: Нужно ли мне как то еще активировать добавленный модуль, чтоб увидеть его при загрузке?**
