#!/bin/bash
#rm tempfile
function strnum {
nameoffile=$1

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

strnum $1 $2
numstr=$?

echo "The new value is" $numstr
echo $numstr