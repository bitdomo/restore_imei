#!/bin/sh
imei1=$1"0"
imei2=$2"0"

echo -n "Writing imei1 to efs: "
for i in $(seq 0 2 14)
do
	echo -n ...
    echo 'AT+GOOGSETNV="CAL.Common.Imei",'$(($i/2))',"'${imei1:$i:2}'"\r' > /dev/umts_router
	sleep 0.5
done
echo " DONE!"

echo -n "Writing imei2 to efs: "
for i in $(seq 0 2 14)
do
	echo -n ...
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
