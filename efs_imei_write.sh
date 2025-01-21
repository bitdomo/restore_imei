#!/bin/sh
check_imei() {
    imei=$1
	echo -n "Checking imei number: "$imei"... "
    case $imei in
        ''|*[!0-9]*) echo "imei number has nonnumerical character"
        exit 255
        ;;
    esac
    if [ ${#imei} -ne 15 ]; then
        echo "imei number has invalid length"
        exit 255
    fi
    sum=0
    for i in $(seq 0 13)
    do
        if [ $((i%2)) -ne 0 ]; then
            temp=$((${imei:$i:1}*2))
            if [ "${#temp}" -eq 2 ]; then
                temp=$((${temp:0:1}+${temp:1:1}))
                sum=$(($sum+$temp))
            else
                sum=$(($sum+$temp))
            fi
        else
        sum=$(($sum+${imei:$i:1}))
        fi
    done
    if [ $((($sum+${imei:14:1})%10)) -ne 0 ]; then
        echo "imei number has invalid Luhn digit"
        exit 255
    fi
	echo "OK!"
}

if [ "$#" -ne 2 ]; then
	echo "Invalid number of arguments"
    echo "Usage: imei.sh <imei1> <imei2>"
    exit 255
fi

check_imei $1
check_imei $2
imei1=$1"0"
imei2=$2"0"

echo -n "Writing imei1: "
for i in $(seq 0 2 14)
do
	echo -n ${1:$i:2}
    echo 'AT+GOOGSETNV="CAL.Common.Imei",'$(($i/2))',"'${imei1:$i:2}'"\r' > /dev/umts_router
	sleep 0.5
done
echo " DONE!"

echo -n "Writing imei2: "
for i in $(seq 0 2 14)
do
	echo -n ${2:$i:2}
    echo 'AT+GOOGSETNV="CAL.Common.Imei_2nd",'$(($i/2))',"'${imei2:$i:2}'"\r' > /dev/umts_router
	sleep 0.5
done
echo " DONE!"

echo -n "Waiting for nv_protected.bin to be refresshed: "
for i in $(seq 1 5)
do
    echo -n $i"..."
	sleep 1
done
echo " DONE!"

echo -n "Updating efs_backup partition: "
echo 'AT+GOOGBACKUPNV\r' > /dev/umts_router
for i in $(seq 1 5)
do
    echo -n $i"..."
	sleep 1
done
echo " DONE!"
