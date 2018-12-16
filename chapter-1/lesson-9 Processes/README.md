### Процессы

1. Аналог PS

Тут решил вспомнить питон.
Описание полей stat [тут][1]
Описание сокращений us, sy, ni, id, wa, hi, si and st [тут][2]
И простые функции Python тоже подзабылись. Все что нужно знать есть [тут][3]

Скрипт в файле `px-axu.py`

Результат работы выглядит так:
```bash
[root@rpmcreatedandrepo vagrant]# python px-axu.py
NAME             Pid  Status          us    sy  Command
-------------  -----  ------------  ----  ----  -------------------------------------------------------------------
systemd            1  S (sleeping)    19    89  /usr/lib/systemd/systemd--switched-root--system--deserialize22
lru-add-drain     10  S (sleeping)     0     0
watchdog/0        11  S (sleeping)    14     0
master          1175  S (sleeping)     3     1  /usr/libexec/postfix/master-w
qmgr            1186  S (sleeping)     0     1  qmgr-l-tunix-u
sshd            1209  S (sleeping)     0    21  sshd: vagrant [priv]
sshd            1213  S (sleeping)     0    21  sshd: vagrant@pts/0
bash            1214  S (sleeping)     3     2  -bash
sudo            1237  S (sleeping)     0     0  sudosu-
su              1238  S (sleeping)     0     0  su-
```

Можно указать количество выводимых строк (по-умолчанию 10)
```
[root@rpmcreatedandrepo vagrant]# ./px-axu.py 11
```
Есть даже кривенькая сортировка.

Можно добавлять функции в скрип и дальше, но нет времени.

2. Поиграться с приоритетами.
Не сразу нашел хорошую команду длинную и безвредную для выполнения. `dd` почему-то очень быстрый из zero в null
Гугл и запрос "как загрузит ЦПУ" очень помогли.
Я не умею красиво в питоне создавать процуссы с приоритетом, поэтому влоб, `subprocess` в помощь.

Поставил еще pip-python и в нем пакеты/библиотеки хз что это.
Первый потому что красивый, второй потому что хочу при параллельном запуске сравнить время, когда приоритеты могу сыграть роль.
```bash
pip install pprint
pip install futures
```

Скрипт `nice.py`
Результат выполнения:
```bash
[root@rpmcreatedandrepo vagrant]# ./nice.py '+19' '-20'
Nice for first command = 19
Nice for second command = -20
Let's check it

Parallel mode:
Command                                                    Time
---------------------------------------------------------  --------------
nice -n 19 cat 1g.img | nice -n 19 bzip2 -c > /dev/null    0:00:22.195895
nice -n -20 cat 1g.img | nice -n -20 bzip2 -c > /dev/null  0:00:11.423270

Sequence mode:
---------------------------------------------------------  --------------
nice -n 19 cat 1g.img | nice -n 19 bzip2 -c > /dev/null    0:00:10.722184
nice -n -20 cat 1g.img | nice -n -20 bzip2 -c > /dev/null  0:00:11.621411
---------------------------------------------------------  --------------
```

**Вопрос: Почему при последовательном запуске процесс с большим приоритетом медленнее?
Это огреха в постановке эксперимента или есть предпослки такого результата?**

**Вопрос: Я в параллельной вкладке с top ни разу не увидел двух процессов bzip2 с разными приоритетами, так должно быть или я что-то не так сделал?**

---

[1]: http://man7.org/linux/man-pages/man5/proc.5.html
[2]: https://unix.stackexchange.com/questions/18918/in-linux-top-command-what-are-us-sy-ni-id-wa-hi-si-and-st-for-cpu-usage
[3]: https://natenka.gitbooks.io/pyneng/content/