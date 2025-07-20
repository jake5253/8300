#!/bin/sh

#check if UI disable all led
#LED_STATUS=`syscfg get led_ui_rearport`
#if [ "0" == "${LED_STATUS}" ]; then
#	exit 0 
#fi

# blink LED
#Use sysfs interface
if [ -d /sys/class/leds ]; then
	echo timer > /sys/class/leds/panel/trigger
	echo "1000" > /sys/class/leds/panel/delay_on
	echo "1000" > /sys/class/leds/panel/delay_off
	sleep 15
	echo none > /sys/class/leds/panel/trigger
	/etc/led/manage_wan_led.sh 
fi

echo "`date` LED $0 $1 $2 $3" >> /var/log/messages
