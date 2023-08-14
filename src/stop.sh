#!/usr/bin/env sh
pkill -f dash.sh
lipc-set-prop com.lab126.pillow disableEnablePillow enable
sleep 1
initctl start framework
sleep 1
initctl start webreader
sleep 1
echo ondemand >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
lipc-set-prop com.lab126.powerd preventScreenSaver 0