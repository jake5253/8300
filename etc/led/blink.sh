#!/bin/sh
#check if UI disable all led
LED_STATUS=`syscfg get led_ui_rearport`
if [ "0" == "${LED_STATUS}" ]; then
	exit 0 
fi

#Use sysfs interface - fast blinking
if [ -d /sys/class/leds ]; then
	echo heartbeat > /sys/class/leds/panel/trigger
fi

/etc/led/lib_set_solid_after.sh 240 &

echo "`date` LED $0 $1 $2 $3" >> /var/log/messages

