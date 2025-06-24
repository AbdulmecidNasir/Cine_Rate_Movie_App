@echo off
echo Setting DNS settings for Android emulator...
adb shell "su -c 'sh /data/app/assets/dns_settings.sh'"
echo DNS settings have been updated.
pause 