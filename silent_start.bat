@echo off
setlocal enabledelayedexpansion

set /p imei1=imei1:
set /p imei2=imei2:
cls
echo Processing...
adb shell su -c "echo &> /dev/null" 2> NUL
if %ERRORLEVEL%==13 (
    echo FAIL!
	echo Could not get root access
    goto :exit
)
if %ERRORLEVEL%==127 (
    echo FAIL!
	echo Could not find su command
    goto :exit
)

for /f "tokens=2 delims==" %%i in ('"wmic os get localdatetime /value"') do set datetime=%%i
set foldername=!datetime:~0,14!
for /f "tokens=* delims=" %%i in ('adb get-serialno') do set serial=%%i
set foldername=!serial!-!foldername!
mkdir !foldername!
if %ERRORLEVEL%==1 (
    echo Failed to create !foldername! folder
    goto :exit
)

adb shell "su -c dd if=/dev/block/by-name/efs of=/tmp/efs.bak" 2> NUL
adb pull /tmp/efs.bak !foldername!\efs.bak 2> NUL

adb shell "su -c dd if=/dev/block/by-name/efs_backup of=/tmp/efs_backup.bak" 2> NUL
adb pull /tmp/efs_backup.bak !foldername!\efs_backup.bak 2> NUL

adb shell "su -c dd if=/dev/block/by-name/devinfo of=/tmp/devinfo.bak" 2> NUL
adb pull /tmp/devinfo.bak !foldername!\devinfo.bak 2> NUL

adb shell "su -c dd if=/dev/block/by-name/persist of=/tmp/persist.bak" 2> NUL
adb pull /tmp/persist.bak !foldername!\persist.bak 2> NUL

adb push devinfo_imei_write.sh /tmp 2> NUL

adb shell chmod +x /tmp/devinfo_imei_write.sh
adb shell "su -c /tmp/devinfo_imei_write.sh %imei1% %imei2% &> /dev/null"
if %ERRORLEVEL%==255 (
    goto :exit
)

adb pull /tmp/devinfo.mod !foldername!\devinfo.mod 2> NUL

adb reboot bootloader
fastboot oem set_config bootmode factory 2> NUL

fastboot reboot 2> NUL
adb wait-for-device 2> NUL

adb push efs_imei_write.sh /tmp 2> NUL

adb shell chmod +x /tmp/efs_imei_write.sh
adb shell "su -c /tmp/efs_imei_write.sh %imei1% %imei2% &> /dev/null"
if %ERRORLEVEL%==255 (
    goto :exit
)

adb push !foldername!\devinfo.mod /tmp 2> NUL

adb shell "su -c dd if=/tmp/devinfo.mod of=/dev/block/by-name/devinfo" 2> NUL

adb reboot

echo DONE
:exit
pause