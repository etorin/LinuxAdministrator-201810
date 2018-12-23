### Ansible

Подготовить стенд на Vagrant как минимум с одним сервером. На этом сервере используя Ansible необходимо развернуть nginx со следующими условиями:
- необходимо использовать модуль yum/apt
- конфигурационные файлы должны быть взяты из шаблона jinja2 с перемененными
- после установки nginx должен быть в режиме enabled в systemd
- должен быть использован notify для старта nginx после установки
- сайт должен слушать на нестандартном порту - 8080, для этого использовать переменные в Ansible
* Сделать все это с использованием Ansible роли

Основной вопрос, как сделать красиво и с запуском из Vagrant когда у тебя Windows

Я написал сценарий и он заработал. Сейчас хочу чтоб мои локальны файлы со сценарием копировались в виртуальную машину и все само поднималось.
Но, видимо на Windows я должен страдать.

Добавил в Vagrantfile это чтоб поделиться директорией.
```bash
box.vm.synced_folder 'e:\\Vagrant\\hw11\\ansible\\', '/home/vagrant/ansible/'
```

Сначала директория не смогла примонтироваться.
```bash
    hw11Ansible: \/home\/vagrant\/ansible\ => E:/Vagrant/hw11/ansible
Vagrant was unable to mount VirtualBox shared folders. This is usually
because the filesystem "vboxsf" is not available. This filesystem is
made available via the VirtualBox Guest Additions and kernel module.
Please verify that these guest additions are properly installed in the
guest. This is not a bug in Vagrant and is usually caused by a faulty
Vagrant box. For context, the command attempted was:

mount -t vboxsf -o uid=1000,gid=1000 _home__vagrant__ansible__ \\/home\\/vagrant\\/ansible\\

The error output from the command was:

mount: unknown filesystem type 'vboxsf'
```

Такое расширение помогло.
```powershell
vagrant plugin install vagrant-vbguest
```

Помогло решить одну проблему. Но, похоже сломало все остальное.

Теперь при каждом запуске он пробует что-то загрузить у него не получается и ошибка.

**Вопрос: Есть способ это победить?**

```bash
[TESTTEST] No Virtualbox Guest Additions installation found.
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: centos-mirror.rbc.ru
 * extras: centos-mirror.rbc.ru
 * updates: centos-mirror.rbc.ru
Resolving Dependencies
--> Running transaction check
---> Package centos-release.x86_64 0:7-5.1804.el7.centos will be updated
---> Package centos-release.x86_64 0:7-6.1810.2.el7.centos will be an update
--> Finished Dependency Resolution

Dependencies Resolved

================================================================================
 Package              Arch         Version                     Repository  Size
================================================================================
Updating:
 centos-release       x86_64       7-6.1810.2.el7.centos       base        26 k

Transaction Summary
================================================================================
Upgrade  1 Package

Total download size: 26 k
Downloading packages:
No Presto metadata available for base
Public key for centos-release-7-6.1810.2.el7.centos.x86_64.rpm is not installed
warning: /var/cache/yum/x86_64/7/base/packages/centos-release-7-6.1810.2.el7.centos.x86_64.rpm: Header V3 RSA/SHA256 Signature, key ID f4a80eb5: NOKEY
Retrieving key from file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
Importing GPG key 0xF4A80EB5:
 Userid     : "CentOS-7 Key (CentOS 7 Official Signing Key) <security@centos.org>"
 Fingerprint: 6341 ab27 53d7 8a78 a7c2 7bb1 24c6 a8a7 f4a8 0eb5
 Package    : centos-release-7-5.1804.el7.centos.x86_64 (@anaconda)
 From       : /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Updating   : centos-release-7-6.1810.2.el7.centos.x86_64                  1/2
  Cleanup    : centos-release-7-5.1804.el7.centos.x86_64                    2/2
  Verifying  : centos-release-7-6.1810.2.el7.centos.x86_64                  1/2
  Verifying  : centos-release-7-5.1804.el7.centos.x86_64                    2/2

Updated:
  centos-release.x86_64 0:7-6.1810.2.el7.centos

Complete!
Loaded plugins: fastestmirror


Error getting repository data for C7.6.1810-base, repository not found
==> TESTTEST: Checking for guest additions in VM...
    TESTTEST: No guest additions were detected on the base box for this VM! Guest
    TESTTEST: additions are required for forwarded ports, shared folders, host only
    TESTTEST: networking, and more. If SSH fails on this machine, please install
    TESTTEST: the guest additions and repackage the box to continue.
    TESTTEST:
    TESTTEST: This is not an error message; everything may continue to work properly,
    TESTTEST: in which case you may ignore this message.
The following SSH command responded with a non-zero exit status.
Vagrant assumes that this means the command failed!

yum install -y kernel-devel-`uname -r` --enablerepo=C7.6.1810-base --enablerepo=C7.6.1810-updates

Stdout from the command:

Loaded plugins: fastestmirror


Stderr from the command:



Error getting repository data for C7.6.1810-base, repository not found
```

Такое расширение помогло. Снова.
```powershell
vagrant plugin uninstall vagrant-vbguest
```

Видимо задумка не удастся.

```bash
    - name: Copy site config
      template: 
        src: /home/vagrant/default.conf.j2 
        dest: /etc/nginx/nginx.conf
      backup: yes
      notify: Restart nginx
```
Постоянная ошибка!
```bash
    - name: Copy index.html
      ^ here
```
Походу не нравится ему `backup: yes`

**Вопрос: А на самом деле, почему, кто ответит? В моей супер крутой схеме где хост машина Windows есть супер костыль ansible_local. Так вот в вызываемом таким образом сценарии я не смог использовать функцию модуля [template][1] - backup. Вопрос прост, почему?**

Вобщем, начиная без всякой надежды на успех, он таки достигнут.
Сразу скажу, написанную руками роль я запустить не смог.
Если очень хочется проверить - я ее тоже выложил. 

**Вопрос: Может кто-то знает как запустить роль на локальный и на удаленый хост в таких условиях?**

Может нужно просто нужно дожать задачу по аналогии со всеми зависимостями?
Может использовать guest_ansible?
Просто получается, что вроде как содержимое диреттории ansible выложить рядом с запускаемым сценарием, 
но это речь про локальный хост, а я на удаленный все равно шаблоны должен копировать.  
Можно в об накопировать и их shell запустить сценарий, наверное. 
А может, нужно как то по-умному, учитывая что Ansiblе сервер это один из гостевых хостов и файлы для запуска роли точно должны быть там.

Это все пока фразы из середины. А если по порядку, то оказывается для Windows есть супер костыль [ansible_local][3], 
ставится он вместе c `vagrant-guest_ansible` или уже есть - я не заметил. Но отдельно точно не захотел.

```bash
vagrant plugin vagrant-guest_ansible
```

Этот модуль на гостевую машину будет ставить ansible.
Работающий участок кода:
```ruby
      box.vm.provision :ansible_local do |guest_ansible|
        guest_ansible.inventory_path = "hosts"
        guest_ansible.playbook = "playbook.yml"
        guest_ansible.sudo = true
      end
```
без `hosts` ругается на отстутсвие.

Так вот, как мы настраивали гостевую машину через shell так ее можно и через ansble, но в данном случае локальном запущенным на localhost.
В качестве костыля пойдет, но хотелось бы иметь один сервер откуда все сценарии запускаем.

Еще один модуль [копирование файлов][2]. Синхронизация не пошла, зато это взлетело без проблем.
Локальный путь - относительно Vagrantfile.
```ruby
      box.vm.provision "file", source: "ansible", destination: "/home/vagrant/ansible" # directory
      box.vm.provision "file", source: "default.conf.j2", destination: "/home/vagrant/default.conf.j2" # file
      box.vm.provision "file", source: "index.html.j2", destination: "/home/vagrant/index.html.j2" # file
```
Инвентарный файл, и имя такое же как в Vagrantfile, вроде при несовпадении ругался, хотя странно, какая ему разница, он же на localhost идет.
Кстати, я пробовал указыавать ssh и все что нужно, порт, имя, пароль - так и не смог подключиться. Может особенность `ansible_local` непонятно.
```bash
TESTTEST ansible_connection=local
```
Сам `playbook.yml` сценарий постотрите в git. 
Есть хороший готовый [пример][4] который очень помог сдвинуться с точки.

По сути задачи nginx тоже были проблемы, не смог создать отдельную директорию с отделным конфигом как [тут][5] - переписал параметры по-умолчанию.
[Тоже пригодилось.][6]

`http://192.168.33.15:8080/`


PS. Vagrantfile-first приложе просто чтоб не забыть как 2 разные машины конфигурировать и что накопировав лоль на одну, можно запустить ее на вторую.
Это была первая реализация роли.

---

[1]: https://docs.ansible.com/ansible/latest/modules/template_module.html
[2]: https://www.vagrantup.com/docs/provisioning/file.html
[3]: https://www.vagrantup.com/docs/provisioning/ansible_local.html
[4]: https://github.com/tumf/vagrant-ansible_local-centos7-sample/blob/master/provision.yml
[5]: https://blog.amet13.name/2016/02/ansible-playbook-nginx.html
[6]: https://ruhighload.com/nginx.conf