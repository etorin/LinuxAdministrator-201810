#!/bin/bash
# Defaults values

######
# Первая часть для блокировки повторного запуска
LOCK=/var/tmp/initplock
if [ -f $LOCK ]; then
 echo Job is already running\!
 exit 6
fi
touch $LOCK
trap 'rm -f "$LOCK"; exit $?' INT TERM EXIT
######

request_type="GET\|POST"
filename="access.log"
amount_of_ip=10
templine=templine

# Тут нашел хороший парсинг ключей
while [ -n "$1" ]
do
case "$1" in
-f) filename="$2"
#echo "File name is $filename" 
shift ;;
-t) request_type="$2"
#echo "request type $request_type" 
shift ;;
-l) templine="$2"
#echo "request type $request_type" 
shift ;;
-n) amount_of_ip="$2"
#echo "Amount of ip $amount_of_ip" 
shift ;;
-h) echo "Script po parse nginx access log
Keys:

-f file name
-t GET or POST request_type
-n Amount of ip to print
-h help page

" 
shift ;;
--) shift
break ;;
*) echo "$1 is not an option";;
esac
shift
done
count=1
for param in "$@"
do
echo "Parameter #$count: $param"
count=$(( $count + 1 ))
done

####################################
# Тут вставляем функцию поиска номера строки - если ненайдена - 0 - значит с начала файла
function strnum {
nameoffile=$1

# Подготовка сохраняенной строки к копированию ее в массив
sed -i 's/\[/ /g' $nameoffile
#cat $nameoffile
sed -i 's/\]/ /g' $nameoffile
#cat $nameoffile
sed -i 's/"/ /g' $nameoffile
#cat $nameoffile
sed -i 's/-\s/ /g' $nameoffile
#cat $nameoffile
sed -i 's/\// /g' $nameoffile
#cat $nameoffile
sed -i 's/\s\s\s/ /g' $nameoffile
#cat $nameoffile
sed -i 's/\s\s/ /g' $nameoffile
#cat $nameoffile
sed -i 's/\s\s/ /g' $nameoffile
#cat $nameoffile

# Из первых 10 полей в логе делаю массив
for i in {1..10}; do array[$i]=`cat $nameoffile | cut -f$i -d' '`; done

#for i in "${array[@]}";do
#echo '############################'
#echo $i
#done

echo ${array[1]}
cat $2 | grep -n ${array[1]} > tempfile
cat tempfile | wc -l

for i in {1..10}
do
echo ${array[$i]} #> /dev/null
cat tempfile | grep ${array[$i]} > tempfile
cat tempfile | wc -l
done

number=`cat tempfile | cut -f1 -d':'`
rm -f tempfile
return $number
}

strnum $templine $filename
numstr=$?
echo "The new value is" $numstr
cat $filename | wc -l
tail -n +$numstr $filename > tempaccfile

# Тут логика такая, мы только что порезали файл по предыдущей сроке - последняя строка нового фала должна остаться как ориентир для следующих запусков
# Тут тоже костыль, одно убрать, другой оставить
cat $filename | sed -n 38,38p > templine
# tail -n1 tempaccfile > $templine

cat tempaccfile | wc -l
# Тут, по скольку у меня файла нет обновляемого - костыль - если убрать - поиск будет по срезу файла согласно найденной строки
#filename=tempaccfile
####################################

last_run_time=`date +%s`
echo $last_run_time > last_run_time.tmp

# Тут тоже кривовато - имейл нужно вынести в переменну бы, и все в одно письмо, но у меня и так слишком много времени уходит на элементарные вещи
cat $filename | grep $request_type | awk '{print $1}' | uniq -c | sort -k1nr | head -n $amount_of_ip > mail.txt
echo "Subject: hello Popular IP Source" | sendmail -v localhost < mail.txt
cat mail.txt

cat $filename | awk -F\" '{print $2}' $filename | awk '{print $2}' | sort | uniq -c | sort -k1nr | head -n $amount_of_ip > mail.txt
echo "Subject: hello Popular URL destination" | sendmail -v localhost < mail.txt

cat $filename | awk '{print $9}' $filename | uniq -c | sort -k1nr > mail.txt
echo "Subject: hello Ansver code" | sendmail -v localhost < mail.txt

######
# Завершающая часть для блокировки повторного запуска
rm -f $LOCK
trap - INT TERM EXIT
######