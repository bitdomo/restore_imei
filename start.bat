@echo off
setlocal enabledelayedexpansion

set /p imei1=imei1:
set /p imei2=imei2:

echo|set /p="Checking for root access... "
adb shell su -c "echo &> /dev/null" 2> NUL
if %ERRORLEVEL%==13 (
    echo FAIL^^!
	echo Could not get root access
    goto :exit
)
if %ERRORLEVEL%==127 (
    echo FAIL^^!
	echo Could not find su command
    goto :exit
)
if %ERRORLEVEL%==1 (
    echo FAIL^^!
	echo No adb device found or no permission
    goto :exit
)
echo DONE^^!

for /f "tokens=2 delims==" %%i in ('"wmic os get localdatetime /value"') do set datetime=%%i
set foldername=!datetime:~0,14!
for /f "tokens=* delims=" %%i in ('adb get-serialno') do set serial=%%i
set foldername=!serial!-!foldername!
mkdir !foldername!
if %ERRORLEVEL%==1 (
    echo Failed to create !foldername! folder
    goto :exit
)

echo|set /p="Backing up efs partition... "
adb shell "su -c dd if=/dev/block/by-name/efs of=/tmp/efs.bak" 2> NUL
adb pull /tmp/efs.bak !foldername!\efs.bak 2> NUL
echo DONE^^!

echo|set /p="Backing up efs_backup partition... "
adb shell "su -c dd if=/dev/block/by-name/efs_backup of=/tmp/efs_backup.bak" 2> NUL
adb pull /tmp/efs_backup.bak !foldername!\efs_backup.bak 2> NUL
echo DONE^^!

echo|set /p="Backing up devinfo partition... "
adb shell "su -c dd if=/dev/block/by-name/devinfo of=/tmp/devinfo.bak" 2> NUL
adb pull /tmp/devinfo.bak !foldername!\devinfo.bak 2> NUL
echo DONE^^!

echo|set /p="Backing up persist partition... "
adb shell "su -c dd if=/dev/block/by-name/persist of=/tmp/persist.bak" 2> NUL
adb pull /tmp/persist.bak !foldername!\persist.bak 2> NUL
echo DONE^^!

echo|set /p="Pushing devinfo_imei_write.sh to /tmp... "
adb push devinfo_imei_write.sh /tmp 2> NUL
echo DONE^^!

echo Running devinfo_imei_write.sh
adb shell chmod +x /tmp/devinfo_imei_write.sh
adb shell su -c /tmp/devinfo_imei_write.sh %imei1% %imei2%
if %ERRORLEVEL%==255 (
    goto :exit
)
echo Script devinfo_imei_write.sh has finished running

echo|set /p="Pulling devinfo.mod... "
adb pull /tmp/devinfo.mod !foldername!\devinfo.mod 2> NUL
echo DONE^^!

echo|set /p="Setting factory boot mode... "
adb reboot bootloader
fastboot oem set_config bootmode factory 2> NUL
echo DONE^^!

echo|set /p="Rebooting phone in factory boot mode... "
fastboot reboot 2> NUL
adb wait-for-device 2> NUL
echo DONE^^!

echo|set /p=Waiting for 15 seconds for the phone to boot up... "
ping -n 15 127.0.0.1 > nul
echo DONE^^!

echo|set /p="Pushing efs_imei_write.sh to /tmp... "
adb push efs_imei_write.sh /tmp 2> NUL
echo DONE^^!


adb shell "su -c 'if [[ $(cat /mnt/vendor/persist/modem/cpsha) ^!= $(echo \"AT+GOOGGETIMEISHA\r\" > /dev/umts_router & cat /dev/umts_router | strings | grep +GOOGGETIMEISHA: | sed \"s/^................//\") ]]; then echo \"IMEI sha check failed!\"; exit 254; fi'"
if %ERRORLEVEL%==254 (
    echo|set /p="Reverting changes... "
	adb push !foldername!\devinfo.bak /tmp 2> NUL
	adb shell "su -c dd if=/tmp/devinfo.bak of=/dev/block/by-name/devinfo" 2> NUL
	echo DONE^^!
	echo|set /p="Rebooting..."
	adb reboot
	echo DONE^^!
	goto :exit
)

echo Running efs_imei_write.sh
adb shell chmod +x /tmp/efs_imei_write.sh
adb shell su -c /tmp/efs_imei_write.sh %imei1% %imei2%
if %ERRORLEVEL%==255 (
    goto :exit
)
echo Script efs_imei_write.sh has finished running

echo|set /p="Pushing devinfo.mod... "
adb push !foldername!\devinfo.mod /tmp 2> NUL
echo DONE^^!

echo|set /p="Flashing devinfo.mod to turn off factory mode... "
adb shell "su -c dd if=/tmp/devinfo.mod of=/dev/block/by-name/devinfo" 2> NUL
echo DONE^^!

echo Rebooting and all done.
adb reboot

:exit
pause