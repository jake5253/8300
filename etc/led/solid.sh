#!/bin/sh
#check if UI disable all led

echo default-on > /sys/class/leds/panel/trigger


LED_STATUS=`syscfg get led_ui_rearport`
if [ "0" == "${LED_STATUS}" ]; then
	exit 0 
fi

echo "`date` LED $0 $1 $2 $3" >> /var/log/messages

/etc/led/manage_wan_led.sh&

