@echo off
setlocal enabledelayedexpansion

cls
echo This script can only restore the phone's original imei numbers.
echo https://github.com/bitdomo/restore_imei
echo(
echo ----------------------------------IMEI RESTORE----------------------------------
set /p imei1=imei1: 
set /p imei2=imei2: 
cls

echo This script can only restore the phone's original imei numbers.
echo https://github.com/bitdomo/restore_imei
echo(
echo ----------------------------------IMEI RESTORE----------------------------------
echo|set /p="Checking for root access... "
adb shell su -c "echo &> /dev/null" 2> NUL
if %ERRORLEVEL%==13 (
    echo FAIL^^!
	echo Could not get root access.
    goto :exit
)
if %ERRORLEVEL%==127 (
    echo FAIL^^!
	echo Could not find su command.
    goto :exit
)
if %ERRORLEVEL%==1 (
    echo FAIL^^!
	echo No adb device found or no permission.
    goto :exit
)
if not %ERRORLEVEL%==0 (
    echo FAIL^^!
	echo Unknown error.
    goto :exit
)
echo OK^^!

for /f "delims=" %%i in ('powershell -command "Get-Date -Format yyyyMMddHHmmss"') do set datetime=%%i
set foldername=!datetime!
for /f "tokens=* delims=" %%i in ('adb get-serialno') do set serial=%%i
set foldername=!serial!-!foldername!
mkdir !foldername!
if not %ERRORLEVEL%==0 (
    echo Failed to create !foldername! folder.
    goto :exit
)

echo|set /p="Backing up efs partition... "
adb shell "su -c dd if=/dev/block/by-name/efs of=/tmp/efs.bak" 2> NUL
if not %ERRORLEVEL%==0 (
    echo FAIL^^!
	echo adb shell "su -c dd if=/dev/block/by-name/efs of=/tmp/efs.bak" FAILED^^!
    goto :exit
)
adb pull /tmp/efs.bak !foldername!\efs.bak 2> NUL
if not %ERRORLEVEL%==0 (
    echo FAIL^^!
	echo adb pull /tmp/efs.bak !foldername!\efs.bak FAILED^^!
    goto :exit
)
echo DONE^^!

echo|set /p="Backing up efs_backup partition... "
adb shell "su -c dd if=/dev/block/by-name/efs_backup of=/tmp/efs_backup.bak" 2> NUL
if not %ERRORLEVEL%==0 (
    echo FAIL^^!
	echo adb shell "su -c dd if=/dev/block/by-name/efs_backup of=/tmp/efs_backup.bak" FAILED^^!
    goto :exit
)
adb pull /tmp/efs_backup.bak !foldername!\efs_backup.bak 2> NUL
if not %ERRORLEVEL%==0 (
    echo FAIL^^!
	echo adb pull /tmp/efs_backup.bak !foldername!\efs_backup.bak FAILED^^!
    goto :exit
)
echo DONE^^!

echo|set /p="Backing up devinfo partition... "
adb shell "su -c dd if=/dev/block/by-name/devinfo of=/tmp/devinfo.bak" 2> NUL
if not %ERRORLEVEL%==0 (
    echo FAIL^^!
	echo adb shell "su -c dd if=/dev/block/by-name/devinfo of=/tmp/devinfo.bak" FAILED^^!
    goto :exit
)
adb pull /tmp/devinfo.bak !foldername!\devinfo.bak 2> NUL
if not %ERRORLEVEL%==0 (
    echo FAIL^^!
	echo adb pull /tmp/devinfo.bak !foldername!\devinfo.bak FAILED^^!
    goto :exit
)
echo DONE^^!

echo|set /p="Pushing devinfo_imei_write.sh to /tmp... "
adb push devinfo_imei_write.sh /tmp 2> NUL
if not %ERRORLEVEL%==0 (
    echo FAIL^^!
	echo adb push devinfo_imei_write.sh /tmp FAILED^^!
    goto :exit
)
echo DONE^^!

echo Running devinfo_imei_write.sh.
adb shell chmod +x /tmp/devinfo_imei_write.sh
if not %ERRORLEVEL%==0 (
    echo FAIL^^!
	echo adb shell chmod +x /tmp/devinfo_imei_write.sh FAILED^^!
    goto :exit
)
echo -----------------------------devinfo_imei_write.sh------------------------------
adb shell su -c /tmp/devinfo_imei_write.sh %imei1% %imei2%
if %ERRORLEVEL%==255 (
    goto :exit
)
echo --------------------------------------------------------------------------------
echo Script devinfo_imei_write.sh has finished running.

echo|set /p="Pulling devinfo.mod... "
adb pull /tmp/devinfo.mod !foldername!\devinfo.mod 2> NUL
if not %ERRORLEVEL%==0 (
    echo FAIL^^!
	echo adb pull /tmp/devinfo.mod !foldername!\devinfo.mod FAILED^^!
    goto :exit
)
echo DONE^^!

echo|set /p="Setting factory bootmode... "
adb reboot bootloader
if not %ERRORLEVEL%==0 (
    echo FAIL^^!
	echo adb reboot bootloader FAILED^^!
    goto :exit
)
fastboot oem set_config bootmode factory 2> NUL
if not %ERRORLEVEL%==0 (
    echo FAIL^^!
	echo fastboot oem set_config bootmode factory FAILED^^!
    goto :exit
)
echo DONE^^!

echo|set /p="Rebooting phone in factory bootmode... "
fastboot reboot 2> NUL
if not %ERRORLEVEL%==0 (
    echo FAIL^^!
	echo fastboot reboot FAILED^^!
    goto :exit
)
adb wait-for-device 2> NUL
echo DONE^^!

echo|set /p="Waiting for 15 seconds for the phone to boot up... "
ping -n 15 127.0.0.1 > nul
echo DONE^^!

echo|set /p="Pushing efs_imei_write.sh to /tmp... "
adb push efs_imei_write.sh /tmp 2> NUL
if not %ERRORLEVEL%==0 (
    echo FAIL^^!
	echo adb push efs_imei_write.sh /tmp FAILED^^!
    goto :exit
)
echo DONE^^!

echo Running efs_imei_write.sh.
echo -------------------------------efs_imei_write.sh--------------------------------
adb shell chmod +x /tmp/efs_imei_write.sh
if not %ERRORLEVEL%==0 (
	echo FAIL^^!
	echo adb shell chmod +x /tmp/efs_imei_write.sh FAILED^^!
	goto :exit
)
adb shell su -c /tmp/efs_imei_write.sh %imei1% %imei2%
echo --------------------------------------------------------------------------------
echo Script efs_imei_write.sh has finished running.

echo|set /p="Pushing devinfo.mod... "
adb push !foldername!\devinfo.mod /tmp 2> NUL
if not %ERRORLEVEL%==0 (
	echo FAIL^^!
	echo adb push !foldername!\devinfo.mod /tmp FAILED^^!
	goto :exit
)
echo DONE^^!

echo|set /p="Flashing devinfo.mod to turn off factory mode... "
adb shell "su -c dd if=/tmp/devinfo.mod of=/dev/block/by-name/devinfo" 2> NUL
if not %ERRORLEVEL%==0 (
	echo FAIL^^!
	echo adb shell "su -c dd if=/tmp/devinfo.mod of=/dev/block/by-name/devinfo" FAILED^^!
	goto :exit
)
echo DONE^^!

echo|set /p="Rebooting phone... "
adb reboot
if not %ERRORLEVEL%==0 (
	echo FAIL^^!
	echo adb reboot FAILED^^!
	goto :exit
)
echo DONE^^!
echo --------------------------------------------------------------------------------
:exit
pause