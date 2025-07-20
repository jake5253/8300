#!/bin/sh
#check if UI disable all led
LED_STATUS=`syscfg get led_ui_rearport`
if [ "0" == "${LED_STATUS}" ]; then
	exit 0 
fi

#Use sysfs interface - pulsate blinking
if [ -d /sys/class/leds ]; then
	echo timer > /sys/class/leds/panel/trigger
	echo "714" > /sys/class/leds/panel/delay_on
	echo "714" > /sys/class/leds/panel/delay_off
fi

echo "`date` LED $0 $1 $2 $3" >> /var/log/messages

