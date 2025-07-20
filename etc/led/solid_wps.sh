#!/bin/sh

if [ -d /sys/class/leds/wps ]; then
	echo default-on > /sys/class/leds/wps/trigger
	sleep 5
	echo none > /sys/class/leds/wps/trigger
	#/etc/led/manage_wan_led.sh 
fi

echo "`date` LED $0 $1 $2 $3" >> /var/log/messages

