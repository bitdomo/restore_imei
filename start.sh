#!/bin/bash

clear
echo "This script can only restore the phone's original imei numbers."
echo "https://github.com/bitdomo/restore_imei"
echo
echo "----------------------------------IMEI RESTORE----------------------------------"
read -p "imei1: " imei1
read -p "imei2: " imei2
clear

echo "This script can only restore the phone's original imei numbers."
echo "https://github.com/bitdomo/restore_imei"
echo
echo "----------------------------------IMEI RESTORE----------------------------------"
echo -n "Checking for root access... "
adb shell su -c "echo &> /dev/null" &> /dev/null
case $? in
    13)
        echo "FAIL!"
        echo "Could not get root access."
        exit
        ;;
    127)
        echo "FAIL!"
        echo "Could not find su command."
        exit
        ;;
    1)
        echo "FAIL!"
        echo "No adb device found or no permission."
        exit
        ;;
    0)
        echo "OK!"
        ;;
    *)
        echo "FAIL!"
        echo "Unknown error."
        exit
        ;;
esac

foldername=$(adb get-serialno)-$(date +"%Y%m%d%H%M%S")
mkdir $foldername
if [ "$?" -ne 0 ]; then
    echo Failed to create $foldername folder.
    exit
fi

for partition in efs efs_backup devinfo persist
do
    echo -n "Backing up $partition partition... "
    adb shell "su -c dd if=/dev/block/by-name/$partition of=/tmp/$partition.bak" &> /dev/null
    if [ "$?" -ne 0 ]; then
        echo "adb shell \"su -c dd if=/dev/block/by-name/$partition of=/tmp/$partition.bak\" FAILED!"
        exit
    fi
    adb pull /tmp/$partition.bak $foldername/$partition.bak &> /dev/null
    if [ "$?" -ne 0 ]; then
        echo "adb pull /tmp/$partition.bak $foldername/$partition.bak FAILED!"
        exit
    fi
    echo "DONE!"
done

echo -n "Pushing devinfo_imei_write.sh to /tmp... "
adb push devinfo_imei_write.sh /tmp &> /dev/null
if [ "$?" -ne 0 ]; then
    echo "FAIL!"
    echo "adb push devinfo_imei_write.sh /tmp FAILED!"
    exit
fi
echo "DONE!"

echo "Running devinfo_imei_write.sh."
adb shell chmod +x /tmp/devinfo_imei_write.sh &> /dev/null
if [ "$?" -ne 0 ]; then
    echo "FAIL!"
    echo "adb shell chmod +x /tmp/devinfo_imei_write.sh FAILED!"
    exit
fi
echo "-----------------------------devinfo_imei_write.sh------------------------------"
adb shell su -c /tmp/devinfo_imei_write.sh $imei1 $imei2
if [ "$?" -eq 255 ]; then
    exit
fi
echo "--------------------------------------------------------------------------------"
echo "Script devinfo_imei_write.sh has finished running."

echo -n "Pulling devinfo.mod... "
adb pull /tmp/devinfo.mod $foldername/devinfo.mod &> /dev/null
if [ "$?" -ne 0 ]; then
    echo "FAIL!"
    echo "adb pull /tmp/devinfo.mod $foldername/devinfo.mod FAILED!"
    exit
fi
echo "DONE!"

echo -n "Setting factory bootmode... "
adb reboot bootloader
if [ "$?" -ne 0 ]; then
    echo "FAIL!"
    echo "adb reboot bootloader FAILED!"
    exit
fi
fastboot oem set_config bootmode factory &> /dev/null
if [ "$?" -ne 0 ]; then
    echo "FAIL!"
    echo "fastboot oem set_config bootmode factory FAILED!"
    exit
fi
echo "DONE!"

echo -n "Rebooting phone in factory bootmode... "
fastboot reboot &> /dev/null
if [ "$?" -ne 0 ]; then
    echo "FAIL!"
    echo "fastboot reboot FAILED!"
    exit
fi
adb wait-for-device &> /dev/null
echo "DONE!"

echo -n "Waiting for 15 seconds for the phone to boot up... "
sleep 15
echo "DONE!"

echo -n "Pushing efs_imei_write.sh to /tmp... "
adb push efs_imei_write.sh /tmp &> /dev/null
if [ "$?" -ne 0 ]; then
	echo "FAIL!"
	echo "adb push efs_imei_write.sh FAILED!"
	exit
fi
echo "DONE!"

echo "Running efs_imei_write.sh."
echo "-------------------------------efs_imei_write.sh--------------------------------"
adb shell chmod +x /tmp/efs_imei_write.sh
if [ "$?" -ne 0 ]; then
	echo "FAIL!"
	echo "adb shell chmod +x /tmp/efs_imei_write.sh FAILED!"
	exit
fi
adb shell su -c /tmp/efs_imei_write.sh $imei1 $imei2
echo "--------------------------------------------------------------------------------"
echo "Script efs_imei_write.sh has finished running."

echo -n "Pushing devinfo.mod... "
adb push $foldername/devinfo.mod /tmp &> /dev/null
if [ "$?" -ne 0 ]; then
    echo "FAIL!"
    echo "adb push $foldername/devinfo.mod /tmp FAILED!"
    exit
fi
echo "DONE!"

echo -n "Flashing devinfo.mod to turn off factory mode... "
adb shell "su -c dd if=/tmp/devinfo.mod of=/dev/block/by-name/devinfo" &> /dev/null
if [ "$?" -ne 0 ]; then
    echo "FAIL!"
    echo "adb shell \"su -c dd if=/tmp/devinfo.mod of=/dev/block/by-name/devinfo\" FAILED!"
    exit
fi
echo "DONE!"

echo -n "Rebooting phone... "
adb reboot
if [ "$?" -ne 0 ]; then
    echo "FAIL!"
    echo "adb reboot FAILED!"
    exit
fi
echo "DONE!"
echo --------------------------------------------------------------------------------