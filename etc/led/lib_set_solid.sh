#!/bin/sh
#check if UI disable all led
LED_STATUS=`syscfg get led_ui_rearport`
if [ "0" == "${LED_STATUS}" ]; then
	exit 0 
fi

#Civic use sysfs 
if [ -d /sys/class/leds ]; then
	echo default-on > /sys/class/leds/panel/trigger
fi

