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

echo -n "Writing imei1 and imei2 to devinfo... "
cp /tmp/devinfo.bak /tmp/devinfo.mod &> /dev/null
echo -n $1 | dd of=/tmp/devinfo.mod seek=$(($(strings -t d /tmp/devinfo.mod | grep imei1 | sed 's/......$//') + 6)) bs=1 conv=notrunc count=15 &> /dev/null
echo -n $2 | dd of=/tmp/devinfo.mod seek=$(($(strings -t d /tmp/devinfo.mod | grep imei2 | sed 's/......$//') + 6)) bs=1 conv=notrunc count=15 &> /dev/null
dd if=/tmp/devinfo.mod of=/dev/block/by-name/devinfo &> /dev/null
echo "DONE!"