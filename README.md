# These scripts are to restore the phone's <font color="red">original</font> IMEI number on Pixel 9 Pro XL.

**It will not work if you want to change the phone's imei number to something other than what it had originally.**

It will also not work if both efs and efs_backup partitions got corrupted or wiped or your device has hardware failure.

It might work for other Pixel devices that have the Shannon based modem from Samsung.
This includes every device from Pixel 6 to Pixel 9 and all its variants and Pixel Fold.
I did the testing on my own Pixel 9 Pro XL so I am 100% sure it works.
Other than that I only had the chance to test it on a Pixel 7 and it worked for it too.

## Requirement
- Latest android platform-tools from Google.
- Android platform-tools either added to %PATH% or place the script files to the platform-tools folder.
- The phone must be rooted.
- Have USB debugging enabled.
- Adb shell must have superuser permissions granted.

I only tested it with magisk. Other rooting methods might work too.
## Run
- You run start.bat
- Enter imei1 and imei2 numbers your phone had and just let it run.

You can find your original imei numbers on your phone's box, or on the receipt you got for your phone.
You can also find imei1 on the sim card tray. From that you can calculate imei2. Remove the last digit from imei1 and increase it by 1. Then type the number you get to https://www.imei.info/calc/ to get the last digit.
For example, the sim tray reads `111111111111119`. You remove the last digit you get `11111111111111`. Then you increase it by one you get `11111111111112`. Then from the link above you get `111111111111127`.

You can find your backups in the scripts' folder named \<serial number\>-\<date and time\>

## Technicalities
You can find the imei number on the devinfo partition. If you take a dump of it and open it in a hex editor you can find it after imei1 and imei2 texts.

You can also get the imei numbers read from fastboot mode with `fastboot oem get_config imei1` and `fastboot oem get_config imei2` commands.

The imei numbers entered to start.bat are written back to the **devinfo partition**. This modified devinfo partition is backed because the next step will modify it.

Then the phone reboots to bootloader and `fastboot oem set_config bootmode factory` command is issued. This sets a flag on the devinfo partition to boot the phone in factory mode.
In factory boodmode we can send the `AT+GOOGGETIMEISHA` command to the modem and read the response with

`echo "AT+GOOGGETIMEISHA\r" > /dev/umts_router & cat /dev/umts_router` command.
It will return an SHA value that is checked against the content of */mnt/vendor/persist/modem/cpsha* file. If it fails to match then all changes made to the phone are reverted.
If it is a match then the user will be asked to check if their imei numbers are back or not. Simply hitting enter skips writing back the imei number to the efs, if `efs` has been given as anwser then the script proceeds to write back the imei to the efs with

`echo 'AT+GOOGSETNV="CAL.Common.Imei",X,"YY"\r' > /dev/umts_router & cat /dev/umts_router` command to write back imei1 where **X** goes from 0 to 7 and **YY** is two digits of the imei number.
So if X=0 then this means the first two numbers, if X=1 then this means 3rd and 4th numbers of the imei and so on. Similarly for imei2 the 

`echo 'AT+GOOGSETNV="CAL.Common.Imei_2nd",X,"YY"\r' > /dev/umts_router & cat /dev/umts_router` command is used.
Then with `echo 'AT+GOOGBACKUPNV\r' > /dev/umts_router` we update the **efs_backup** partition so the changes will persist when we decide to factory reset our phone at some point.
Then we flash back the modified devinfo before the factory bootmode flag was set, then the phone reboots. It is also possible to disable factory bootmode with `fastboot oem rm_config bootmode` command.

## TODO

### - ~~Don't touch the efs if writing back the original imei numbers fixes the issue.~~
Throughout my testing, just simply writing back my original imei to the devinfo partition made me get back my imei numbers.
It might be unnecessary to touch the efs. In case just restoring the imei number does not fix the issue then we proceed to write back the imei number to the efs too.

This Pixel 9 Pro XL I have only lost its imei numbers after I did a factory reset after editing the devinfo partition.
Even after that my imei number wasn't zeroed out like on other pixel devices. Simply imei1 and imei2 numbers became the imei number of an old Nokia 6310's imei number. Network connectivity wasn't lost.
However by simply writing back the original imei number to the devinfo partition I got back my imei numbers.

Furthermore I tested with my original devinfo partition what happens if I delete *nv_normal.bin* and related files from */mnt/vendor/efs* but it seemed to have no effect.
After the reboot everything was normal and *nv_normal.bin* and related files have been regenerated.

Then I tested what happens if I delete everything from */mnt/vendor/efs* folder. I don't quite remember what was the outcome of that, but I believe I lost my imei number but after doing a factory reset it got restored.
I assume factory reset restores the efs partition from efs_backup partition.

My final test was what happens if I delete the content of both efs and efs_backup partitions. I still had my imei number after a factory reset but all connectivity was lost.
I could manually connect to my provider's 2G network just fine, but I had no data connection. I did not test if I can make phone calls or send and receive sms.

### - More error handling
The script just assumes everything is going fine and does not detect errors at all. This is dangerous and possibly involves high risk to brick the phone if actually something goes wrong as we modify and flash important system partitions.

### - Logging
It would be nice to log the entire process if something goes bad then I could debug what went wrong and when and why.

### - Colours and better formatting.
I want to make it clear what is actually going on with the phone. I thought adding colours could increase visual clarity.

### - Linux support.
I will rewrite start.bat to work on linux. Writing a batch file is quite a challenge itself. Also for some reason the same batch script works differently on another windows machine.
For example throughout my testings the `echo|set /p="some text"` simply did not work on the person's windows machine who had a Pixel 7 device with zeroed imei number.
I believe rewriting start.bat to Linux's shell script would eliminate the uncertainty, instability and compatibility issues that come with windows.

## Sources and tools I used to make this happen

- My common sense.
- Pixel 9 Pro XL
- Ghidra: https://ghidra-sre.org
- https://github.com/davwheat/shannon-pixel-modem-nvitem-enabler-scripts
- https://gopherproxy.meulie.net/hoi.st/0/posts/2024-03-11-the-graphene-saga-part-1.txt
- https://gopherproxy.meulie.net/hoi.st/0/posts/2024-03-18-the-graphene-saga-part-2.txt
- https://gopherproxy.meulie.net/hoi.st/0/docs/own/pixel-6-imei.txt
